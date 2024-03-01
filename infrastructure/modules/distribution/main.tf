###############################
### CloudFront Distribution ###
###############################

# IAM
data "aws_s3_bucket" "build" {
  bucket = var.s3_build_bucket_id
}

data "aws_iam_policy_document" "build" {
  statement {
    actions = ["s3:GetObject"]

    resources = [data.aws_s3_bucket.build.arn, "${data.aws_s3_bucket.build.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.website.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "build" {
  bucket = data.aws_s3_bucket.build.id
  policy = data.aws_iam_policy_document.build.json
}

# CORS
resource "aws_s3_bucket_cors_configuration" "build" {
  bucket = data.aws_s3_bucket.build.id

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
  }
}


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

# Cloudfront
resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [var.domain_name, "www.${var.domain_name}"]
  web_acl_id          = var.web_acl_id
  price_class         = var.build_environment == "production" ? "PriceClass_All" : "PriceClass_100"

  origin {
    domain_name              = data.aws_s3_bucket.build.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
    origin_id                = "${var.project_name}-${var.build_environment}"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 404
    response_page_path = "/404.html"
  }

  default_cache_behavior {
    cache_policy_id        = aws_cloudfront_cache_policy.website.id
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "${var.project_name}-${var.build_environment}"
    viewer_protocol_policy = "redirect-to-https"

    lambda_function_association {
      event_type = "viewer-request"
      lambda_arn = var.lambda_arn
    }
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
