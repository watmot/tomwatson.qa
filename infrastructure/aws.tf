locals {
  domain_name        = "tomwatson.qa"
  project_name       = "tomwatsonqa-website"
  build_environments = var.build_environments
}

data "aws_route53_zone" "website" {
  name         = local.domain_name
  private_zone = false
}

#####################
### Website Build ###
#####################

module "build" {
  source = "./modules/build"

  project_name       = local.project_name
  build_environments = local.build_environments
  repository_id      = var.repository_id
}

#######################
### SSL Certificate ###
#######################

module "certificate" {
  source = "./modules/certificate"

  providers = {
    aws = aws.use1
  }

  for_each = local.build_environments

  domain_name     = each.value != "production" ? "${each.value}.${local.domain_name}" : local.domain_name
  route53_zone_id = data.aws_route53_zone.website.zone_id
}

############################
### Website Distribution ###
############################

module "distribution" {
  source = "./modules/distribution"

  for_each = local.build_environments

  project_name                         = local.project_name
  domain_name                          = each.value != "production" ? "${each.value}.${local.domain_name}" : local.domain_name
  build_environment                    = each.value
  s3_build_bucket_regional_domain_name = module.build.s3_build_bucket_regional_domain_names[each.key]
  route53_zone_id                      = data.aws_route53_zone.website.zone_id
  acm_certificate_id                   = module.certificate[each.key].acm_certificate_id
}
