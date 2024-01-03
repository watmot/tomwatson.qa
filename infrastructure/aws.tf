locals {
  domain_name        = "tomwatson.qa"
  project_name       = "tomwatsonqa-website"
  build_environments = toset(["dev", "test", "staging", "production"])
}

data "aws_route53_zone" "website" {
  name         = local.domain_name
  private_zone = false
}

############################
### Static Website Build ###
############################

module "static_website" {
  source = "./modules/static_website"

  for_each = local.build_environments

  project_name      = local.project_name
  build_environment = each.key
}

###########
### ACM ###
###########

resource "aws_acm_certificate" "website" {
  for_each = local.build_environments

  domain_name               = each.key != "production" ? "${each.key}.${local.domain_name}" : local.domain_name
  subject_alternative_names = ["www.${each.key != "production" ? "${each.key}.${local.domain_name}" : local.domain_name}"]
  validation_method         = "DNS"
}

resource "aws_route53_record" "website" {
  for_each = {
    for dvo in aws_acm_certificate.website.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.website.zone_id
}

resource "aws_acm_certificate_validation" "website" {
  certificate_arn         = aws_acm_certificate.website.arn
  validation_record_fqdns = [for record in aws_route53_record.cert : record.fqdn]
}

##################
### CloudFront ###
##################

resource "aws_cloudfront_origin_access_control" "website" {
  for_each = local.build_environments

  name                              = "${local.project_name}-${each.key}"
  description                       = "${local.project_name}-${each.key} access control policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "website" {
  for_each = local.build_environments
  origin {
    domain_name              = aws_s3_bucket.build[each.key].bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.website[each.key].id
    origin_id                = "${local.project_name}-${each.key}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = [each.key != "production" ? "${each.key}.${local.domain_name}" : local.domain_name, "www.${each.key != "production" ? "${each.key}.${local.domain_name}" : local.domain_name}"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "${local.project_name}-${each.key}"

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = aws_acm_certificate.cert.arn
  }
}

###############
### Route53 ###
###############

# Root website domain
resource "aws_route53_record" "root" {
  for_each = local.build_environments

  name    = each.key != "production" ? "${each.key}.${local.domain_name}" : local.domain_name
  zone_id = data.aws_route53_zone.website.zone_id
  type    = "A"
  ttl     = "300"
  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = true
  }
}

# www subdomain
resource "aws_route53_record" "www" {
  for_each = local.build_environments

  name    = "www.${each.key != "production" ? "${each.key}.${local.domain_name}" : local.domain_name}"
  zone_id = data.aws_route53_zone.website.zone_id
  type    = "A"
  ttl     = "300"
  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = true
  }
}
