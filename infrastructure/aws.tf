locals {
  project_name = "tomwatsonqa-website"
  build_environments = toset(["dev", "test", "staging", "production"])
}

##########
### S3 ###
##########

# Build files
resource "aws_s3_bucket" "build" {
  for_each = local.build_environments

  bucket = "${local.project_name}-${each.key}-build"
}

resource "aws_s3_bucket_ownership_controls" "build" {
  for_each = local.build_environments

  bucket = aws_s3_bucket.build[each.key].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "build_acl" {
  for_each = local.build_environments

  depends_on = [aws_s3_bucket_ownership_controls.build]

  bucket = aws_s3_bucket.build[each.key].id
  acl    = "private"
}

# CodePipeline Artifacts
resource "aws_s3_bucket" "codepipeline" {
  for_each = local.build_environments

  bucket = "${local.project_name}-${each.key}-codepipeline"
}

resource "aws_s3_bucket_ownership_controls" "codepipeline" {
  for_each = local.build_environments

  bucket = aws_s3_bucket.codepipeline[each.key].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "codepipeline_acl" {
  for_each = local.build_environments

  depends_on = [aws_s3_bucket_ownership_controls.codepipeline]

  bucket = aws_s3_bucket.codepipeline[each.key].id
  acl    = "private"
}