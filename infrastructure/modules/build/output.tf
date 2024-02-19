output "s3_build_bucket_ids" {
  value = {
    for k, v in aws_s3_bucket.build : k => v.id
  }
  description = "Map of the build environments and corresponding bucket names ({env: name})."
}
