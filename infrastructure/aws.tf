locals {
  domain_name        = "tomwatson.qa"
  project_name       = "tomwatsonqa-website"
  build_environments = toset(["dev", "test", "staging", "production"])
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

  for_each = local.build_environments

  project_name      = local.project_name
  build_environment = each.key
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

  domain_name     = each.key != "production" ? "${each.key}.${local.domain_name}" : local.domain_name
  route53_zone_id = data.aws_route53_zone.website.zone_id
}

############################
### Website Distribution ###
############################

module "distribution" {
  source = "./modules/distribution"

  for_each = local.build_environments

  project_name                         = local.project_name
  domain_name                          = each.key != "production" ? "${each.key}.${local.domain_name}" : local.domain_name
  build_environment                    = each.key
  s3_build_bucket_regional_domain_name = module.build[each.key].s3_build_bucket_regional_domain_name
  route53_zone_id                      = data.aws_route53_zone.website.zone_id
  acm_certificate_id                   = module.certificate[each.key].acm_certificate_id
}
