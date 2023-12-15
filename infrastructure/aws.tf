locals {
  project_name = "tomwatsonqa-website"
  build_environments = ["dev", "test", "staging", "production"]
}

##########
### S3 ###
##########

# Build files
resource "aws_s3_bucket" "build" {
  for_each = toset(local.build_environments)

  bucket = "${local.project_name}-build-${each.key}"
}

resource "aws_s3_bucket_acl" "build_acl" {
  bucket = aws_s3_bucket.build.id
  acl    = "private"
}

# CodePipeline Artifacts
resource "aws_s3_bucket" "codepipeline" {
  for_each = toset(local.build_environments)

  bucket = "${local.project_name}-codepipeline-${each.key}"
}

resource "aws_s3_bucket_acl" "codepipeline_acl" {
  bucket = aws_s3_bucket.codepipeline.id
  acl    = "private"
}