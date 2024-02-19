locals {
  build_environment_branches = toset([for env in var.build_environments : env.branch])
}

##########
### S3 ###
##########

# Build files. 
# We create a seperate bucket for each build environment
resource "aws_s3_bucket" "build" {
  for_each = var.build_environments_names

  bucket = "${var.project_name}-${each.value}-build"
}

resource "aws_s3_bucket_ownership_controls" "build" {
  for_each = var.build_environments_names

  bucket = aws_s3_bucket.build[each.value].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "build_acl" {
  for_each = var.build_environments_names

  depends_on = [aws_s3_bucket_ownership_controls.build]

  bucket = aws_s3_bucket.build[each.value].id
  acl    = "private"
}

# CodePipeline Artifacts. 
# We only need to create a single bucket for this, and it
# will hold artifacts named relative to their env.
resource "aws_s3_bucket" "codepipeline" {
  for_each = local.build_environment_branches

  bucket = "${var.project_name}-${each.value}-codepipeline"
}

resource "aws_s3_bucket_ownership_controls" "codepipeline" {
  for_each = local.build_environment_branches

  bucket = aws_s3_bucket.codepipeline[each.value].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "codepipeline_acl" {
  for_each = local.build_environment_branches

  depends_on = [aws_s3_bucket_ownership_controls.codepipeline]

  bucket = aws_s3_bucket.codepipeline[each.value].id
  acl    = "private"
}

####################
### CodePipeline ###
####################

# IAM
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

resource "aws_iam_role" "codepipeline_role" {
  name               = "${var.project_name}-codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "codepipeline_policy" {

  # S3
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = concat(
      [for s in var.build_environments_names : aws_s3_bucket.build[s].arn],
      [for s in var.build_environments_names : "${aws_s3_bucket.build[s].arn}/*"],
      [for s in local.build_environment_branches : aws_s3_bucket.codepipeline[s].arn],
      [for s in local.build_environment_branches : "${aws_s3_bucket.codepipeline[s].arn}/*"],
    )
  }

  # Codestar
  statement {
    effect    = "Allow"
    actions   = ["codestar-connections:UseConnection"]
    resources = [aws_codestarconnections_connection.website.arn]
  }

  # Codebuild
  statement {
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]

    resources = [for s in var.build_environments_names : aws_codebuild_project.website[s].arn]
  }

  # Logs
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "${var.project_name}-codepipeline-policy"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}

# CodeStarConnection
resource "aws_codestarconnections_connection" "website" {
  name          = "${var.project_name}-codestar"
  provider_type = "GitHub"
}

# CodeBuild
resource "aws_codebuild_project" "build" {
  for_each = var.build_environments_names

  name         = "${var.project_name}-${each.value}-codebuild"
  service_role = aws_iam_role.codepipeline_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "app/buildspec/build.yml"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    type         = "LINUX_CONTAINER"
    image        = "aws/codebuild/standard:7.0"
  }
}

resource "aws_codebuild_project" "deploy" {
  for_each = var.build_environments_names

  name         = "${var.project_name}-${each.value}-codebuild"
  service_role = aws_iam_role.codepipeline_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "app/buildspec/deploy.yml"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    type         = "LINUX_CONTAINER"
    image        = "aws/codebuild/standard:7.0"

    environment_variable {
      name  = "DEST_BUCKET"
      type  = "PLAINTEXT"
      value = aws_s3_bucket.build.id
    }
  }
}

# CodePipeline
resource "aws_codepipeline" "website" {
  for_each = local.build_environment_branches

  name     = "${var.project_name}-${each.value}-codepipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline[each.value].bucket
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
        BranchName       = each.value
      }
    }
  }

  dynamic "stage" {
    for_each = {
      for env in var.build_environments : env.run_order => env
      if env.branch == each.value
    }

    content {
      name = title(stage.value.name)


      action {
        name             = "Build"
        category         = "Build"
        owner            = "AWS"
        provider         = "CodeBuild"
        version          = "1"
        input_artifacts  = ["source_output"]
        output_artifacts = ["${stage.value.name}-build_output"]
        run_order        = 1

        configuration = {
          ProjectName = aws_codebuild_project.build[stage.value.name].name
        }
      }

      action {
        name            = "Deploy"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        version         = "1"
        input_artifacts = ["${stage.value.name}-build_output"]
        run_order       = 2

        configuration = {
          ProjectName = aws_codebuild_project.deploy[stage.value.name].name
        }
      }
    }
  }
}
