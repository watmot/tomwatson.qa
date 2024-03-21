output "s3_build_bucket_ids" {
  value = {
    for k, v in aws_s3_bucket.build : k => v.id
  }
  description = "Map of the build environments and corresponding bucket names ({env: name})."
}

output "codepipeline_arns" {
  value = [for v in aws_codepipeline.website : v.arn]
}
output "codepipeline_ids" {
  value = [for v in aws_codepipeline.website : v.name]
}
