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
