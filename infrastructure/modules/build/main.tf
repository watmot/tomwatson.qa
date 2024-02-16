##########
### S3 ###
##########

# Build files. 
# We create a seperate bucket for each build environment
resource "aws_s3_bucket" "build" {
  for_each = var.build_environments

  bucket = "${var.project_name}-${each.value}-build"
}

resource "aws_s3_bucket_ownership_controls" "build" {
  for_each = var.build_environments

  bucket = aws_s3_bucket.build[each.key].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "build_acl" {
  for_each = var.build_environments

  depends_on = [aws_s3_bucket_ownership_controls.build]

  bucket = aws_s3_bucket.build[each.key].id
  acl    = "private"
}

# CodePipeline Artifacts. 
# We only need to create a single bucket for this, and it
# will hold artifacts named relative to their env.
resource "aws_s3_bucket" "codepipeline" {
  bucket = "${var.project_name}-codepipeline"
}

resource "aws_s3_bucket_ownership_controls" "codepipeline" {
  bucket = aws_s3_bucket.codepipeline.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "codepipeline_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.codepipeline]

  bucket = aws_s3_bucket.codepipeline.id
  acl    = "private"
}

####################
### CodePipeline ###
####################

# CodeStarConnection
resource "aws_codestarconnections_connection" "website" {
  name          = "${var.project_name}-codestar"
  provider_type = "GitHub"
}

# CodeBuild
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codepipeline" {
  name               = "${var.project_name}-codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "codepipeline" {
  dynamic "statement" {
    for_each = var.build_environments

    content {
      effect = "Allow"

      actions = [
        "s3:GetObject",
        "s3:PutObject"
      ]

      resources = [
        aws_s3_bucket.codepipeline.arn,
        "${aws_s3_bucket.codepipeline.arn}/*",
        aws_s3_bucket.build[statement.key].arn,
        "${aws_s3_bucket.build[statement.key].arn}/*"
      ]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["codestar-connections:UseConnection"]
    resources = [aws_codestarconnections_connection.website.arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]

    resources = ["*"]
  }

}

resource "aws_codebuild_project" "website" {
  for_each = var.build_environments

  name         = "${var.project_name}-${each.value}-codebuild"
  service_role = aws_iam_role.codepipeline.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  source {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    type         = "LINUX_CONTAINER"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
  }
}

# CodePipeline
resource "aws_codepipeline" "website" {
  name     = "${var.project_name}-codepipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      provider         = "CodeStarSourceConnection"
      owner            = "AWS"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.website.arn
        FullRepositoryId = var.repository_id
        BranchName       = "main"
      }
    }
  }

  dynamic "stage" {
    for_each = var.build_environments

    content {
      name = title(stage.value)


      action {
        name             = "Build"
        category         = "Build"
        provider         = "CodeBuild"
        owner            = "AWS"
        version          = "1"
        input_artifacts  = ["source_output"]
        output_artifacts = ["${stage.value}-build_output"]
        run_order        = 1

        configuration = {
          ProjectName = aws_codebuild_project.website[stage.key].name
        }
      }

      action {
        name            = "Deploy"
        category        = "Deploy"
        owner           = "AWS"
        provider        = "S3"
        version         = "1"
        input_artifacts = ["${stage.value}-build_output"]
        run_order       = 2

        configuration = {
          BucketName = aws_s3_bucket.build[stage.key].id
          Extract    = true
        }
      }
    }


  }
}
