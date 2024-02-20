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
}
