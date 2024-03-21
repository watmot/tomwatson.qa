locals {
  domain_name                           = "tomwatson.qa"
  project_name                          = "tomwatsonqa-website"
  build_environments                    = var.build_environments
  build_environments_names              = toset([for env in var.build_environments : env.name])
  build_environments_basic_auth_enabled = { for env in var.build_environments : env.name => env.basic_auth_enabled }
}

# Route53 Zone
data "aws_route53_zone" "website" {
  name         = local.domain_name
  private_zone = false
}

#####################
### Website Build ###
#####################

module "build" {
  source = "./modules/build"

  project_name                 = local.project_name
  build_environments           = local.build_environments
  build_environments_names     = local.build_environments_names
  repository_id                = var.repository_id
  cloudfront_distribution_ids  = { for k, v in module.distribution : k => v.cloudfront_distribution_id }
  cloudfront_distribution_arns = { for k, v in module.distribution : k => v.cloudfront_distribution_arn }
}

#######################
### SSL Certificate ###
#######################

module "certificate" {
  source = "./modules/certificate"

  providers = {
    aws = aws.use1
  }

  for_each = local.build_environments_names

  domain_name     = each.value != "production" ? "${each.value}.${local.domain_name}" : local.domain_name
  route53_zone_id = data.aws_route53_zone.website.zone_id
}

###########
### WAF ###
###########

module "waf" {
  source = "./modules/waf"

  providers = {
    aws = aws.use1
  }

  project_name = local.project_name
}

###################
### Lambda@Edge ###
###################

module "lambda_viewer_request" {
  source = "./modules/lambda_viewer_request"

  providers = {
    aws = aws.use1
  }

  for_each = { for env in local.build_environments : env.name => env }

  project_name       = local.project_name
  build_environment  = each.value.name
  basic_auth_enabled = each.value.basic_auth_enabled
  function_name      = "${local.project_name}-${each.value.name}-viewer-request"
}

module "lambda_origin_request" {
  source = "./modules/lambda_origin_request"

  providers = {
    aws = aws.use1
  }

  for_each = { for env in local.build_environments : env.name => env }

  project_name      = local.project_name
  build_environment = each.value.name
  function_name     = "${local.project_name}-${each.value.name}-origin-request"
}

############################
### Website Distribution ###
############################

module "distribution" {
  source = "./modules/distribution"

  for_each = local.build_environments_names

  project_name              = local.project_name
  domain_name               = each.value != "production" ? "${each.value}.${local.domain_name}" : local.domain_name
  build_environment         = each.value
  s3_build_bucket_id        = module.build.s3_build_bucket_ids[each.value]
  route53_zone_id           = data.aws_route53_zone.website.zone_id
  acm_certificate_id        = module.certificate[each.value].acm_certificate_id
  web_acl_id                = module.waf.web_acl_arn
  viewer_request_lambda_arn = module.lambda_viewer_request[each.key].lambda_arn
  origin_request_lambda_arn = module.lambda_origin_request[each.key].lambda_arn
}

##########################
### CMS Webhook Lambda ###
##########################

# Lambda IAM
data "aws_iam_policy_document" "cms_lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cms_lambda_role" {
  name               = "${local.project_name}-cms-webhook-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.cms_lambda_assume_role.json
}

data "aws_iam_policy_document" "cms_lambda_policy" {
  # CodePipeline
  statement {
     effect = "Allow"

     actions = [
      "codepipeline:StartPipelineExecution"
     ]

     resources = [for arn in module.build.codepipeline_arns : arn]
  }

  # Logs
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "cms_lambda_policy" {
  name   = "${local.project_name}-cms-webhook-lambda-policy"
  role   = aws_iam_role.cms_lambda_role.id
  policy = data.aws_iam_policy_document.cms_lambda_policy.json
}

# Lambda

data "archive_file" "cms_lambda" {
  type        = "zip"
  source_file = "./lambdas/cms_webhook/index.mjs"
  output_path = "lambdas/cms_webhook.zip"
}

resource "aws_lambda_function" "cms_lambda" {
  filename         = data.archive_file.cms_lambda.output_path
  function_name    = "${local.project_name}-cms-webhook"
  role             = aws_iam_role.cms_lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  publish          = true
  source_code_hash = data.archive_file.cms_lambda.output_base64sha256

  environment {
    variables = {
      CODEPIPELINE_IDS = jsonencode(module.build.codepipeline_ids)
    }
  }
}

# API Route

resource "aws_apigatewayv2_api" "root" {
  name          = "${local.project_name}-http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "root" {
  api_id      = aws_apigatewayv2_api.root.id
  name        = "main"
  auto_deploy = true
}

resource "aws_apigatewayv2_deployment" "root" {
  api_id = aws_apigatewayv2_api.root.id

  triggers = {
    redeployment = sha1(join(",", tolist([
      jsonencode(aws_apigatewayv2_integration.cms),
      jsonencode(aws_apigatewayv2_route.cms),
    ])))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lambda_permission" "apigw_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cms_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.root.execution_arn}/*"
}

resource "aws_apigatewayv2_integration" "cms" {
  api_id             = aws_apigatewayv2_api.root.id
  integration_type   = "AWS_PROXY"
  connection_type    = "INTERNET"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.cms_lambda.invoke_arn
}

resource "aws_apigatewayv2_route" "cms" {
  api_id    = aws_apigatewayv2_api.root.id
  route_key = "POST /cms"
  target    = "integrations/${aws_apigatewayv2_integration.cms.id}"
}

