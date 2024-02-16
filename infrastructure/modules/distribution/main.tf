##################
### CloudFront ###
##################

resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "${var.project_name}-${var.build_environment}"
  description                       = "${var.project_name}-${var.build_environment} access control policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_cache_policy" "website" {
  name        = "${var.project_name}-${var.build_environment}"
  min_ttl     = 0
  max_ttl     = 86400
  default_ttl = 3600

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

resource "aws_cloudfront_distribution" "website" {
  origin {
    domain_name              = var.s3_build_bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
    origin_id                = "${var.project_name}-${var.build_environment}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = [var.domain_name, "www.${var.domain_name}"]

  default_cache_behavior {
    cache_policy_id        = aws_cloudfront_cache_policy.website.id
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "${var.project_name}-${var.build_environment}"
    viewer_protocol_policy = "redirect-to-https"
  }


  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = var.acm_certificate_id
    ssl_support_method  = "sni-only"
  }
}

###############
### Route53 ###
###############

# Root website domain
resource "aws_route53_record" "root" {
  name    = var.domain_name
  zone_id = var.route53_zone_id
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "root_AAAA" {
  name    = var.domain_name
  zone_id = var.route53_zone_id
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = true
  }
}

# www subdomain
resource "aws_route53_record" "www" {
  name    = "www.${var.domain_name}"
  zone_id = var.route53_zone_id
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www_AAAA" {
  name    = "www.${var.domain_name}"
  zone_id = var.route53_zone_id
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = true
  }
}
