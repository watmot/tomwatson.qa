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

############################
### Website Distribution ###
############################

module "distribution" {
  source = "./modules/distribution"

  for_each = local.build_environments

  project_name      = local.project_name
  domain_name       = each.key != "production" ? "${each.key}.${local.domain_name}" : local.domain_name
  build_environment = each.key
}
