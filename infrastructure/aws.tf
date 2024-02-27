locals {
  domain_name              = "tomwatson.qa"
  project_name             = "tomwatsonqa-website"
  build_environments       = var.build_environments
  build_environments_names = toset([for env in var.build_environments : env.name])
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

  project_name             = local.project_name
  build_environments       = local.build_environments
  build_environments_names = local.build_environments_names
  repository_id            = var.repository_id
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

# IAM
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${local.project_name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "lambda_policy" {
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

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "${local.project_name}-lambda-policy"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}

# Viewer Request
data "template_file" "lambda_viewer_request" {
  template = file("./lambdas/viewer_request/index.tpl")
  vars = {
    TEST = "Template file working!"
  }
}

data "archive_file" "lambda" {
  type = "zip"
  source {
    content  = data.template_file.lambda_viewer_request.rendered
    filename = "index.mjs"
  }
  output_path = "lambdas/viewer_request.zip"
}

module "lambda_viewer_request" {
  source = "./modules/lambda"

  providers = {
    aws = aws.use1
  }

  for_each = local.build_environments_names

  build_environments_names = local.build_environments_names
  iam_role                 = aws_iam_role.lambda_role.arn
  function_name            = "${local.project_name}-${each.key}-viewer-request"
  output_path              = "./lambdas/viewer_request.zip"
  source_code_hash         = data.archive_file.lambda.output_base64sha256
}

############################
### Website Distribution ###
############################

module "distribution" {
  source = "./modules/distribution"

  for_each = local.build_environments_names

  project_name       = local.project_name
  domain_name        = each.value != "production" ? "${each.value}.${local.domain_name}" : local.domain_name
  build_environment  = each.value
  s3_build_bucket_id = module.build.s3_build_bucket_ids[each.value]
  route53_zone_id    = data.aws_route53_zone.website.zone_id
  acm_certificate_id = module.certificate[each.value].acm_certificate_id
  web_acl_id         = module.waf.web_acl_arn
  lambda_arn         = module.lambda_viewer_request[each.key].lambda_arn
}
