output "s3_build_bucket_regional_domain_names" {
  value = {
    for k, v in aws_s3_bucket.build : k => v.bucket_regional_domain_name
  }
  description = "Map of the build environments and corresponding bucket regional domain names ({env = domain_name})."
}
