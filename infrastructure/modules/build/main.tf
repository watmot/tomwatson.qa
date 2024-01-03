##########
### S3 ###
##########

# Build files
resource "aws_s3_bucket" "build" {
  bucket = "${var.project_name}-${var.build_environment}-build"
}

resource "aws_s3_bucket_ownership_controls" "build" {
  bucket = aws_s3_bucket.build[var.build_environment].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "build_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.build]

  bucket = aws_s3_bucket.build[var.build_environment].id
  acl    = "private"
}

# CodePipeline Artifacts
resource "aws_s3_bucket" "codepipeline" {
  bucket = "${var.project_name}-${var.build_environment}-codepipeline"
}

resource "aws_s3_bucket_ownership_controls" "codepipeline" {
  bucket = aws_s3_bucket.codepipeline[var.build_environment].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "codepipeline_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.codepipeline]

  bucket = aws_s3_bucket.codepipeline[var.build_environment].id
  acl    = "private"
}
