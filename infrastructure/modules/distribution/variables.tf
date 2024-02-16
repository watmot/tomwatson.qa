variable "project_name" {
  type        = string
  description = "The name of the project."
}

variable "domain_name" {
  type        = string
  description = "The domain name of the website."
}

variable "build_environment" {
  type        = string
  description = "The website build environment the infrastructure is used for."
}

variable "s3_build_bucket_regional_domain_name" {
  description = "The regional domain name of the S3 bucket which holds the build files."
}

variable "route53_zone_id" {
  description = "The ID of the Route 53 zone."
}

variable "acm_certificate_id" {
  description = "The ID of the ACM certificate."
}