locals {
  build_environment_branches          = toset([for env in var.build_environments : env.branch])
  build_environment_requires_approval = toset([for env in var.build_environments : env.name if env.requires_approval])
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

###########
### SSM ###
###########
resource "aws_ssm_parameter" "build_environment" {
  for_each = var.build_environments_names

  name  = "${var.project_name}-${each.key}-build-environment"
  type  = "String"
  value = each.key
}

##########################
### CodeStarConnection ###
##########################
resource "aws_codestarconnections_connection" "website" {
  name          = "${var.project_name}-codestar"
  provider_type = "GitHub"
}

#################
### CodeBuild ###
#################
data "aws_iam_policy_document" "codebuild_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Build
resource "aws_iam_role" "codebuild_build" {
  for_each = var.build_environments_names

  name               = "${var.project_name}-${each.key}-codebuild-build-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}

data "aws_iam_policy_document" "codebuild_build" {
  for_each = var.build_environments_names

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:PutObjectAcl",
      "s3:DeleteObject"
    ]

    resources = concat(
      [for env in var.build_environments : aws_s3_bucket.codepipeline[env.branch].arn if env.name == each.key],
      [for env in var.build_environments : "${aws_s3_bucket.codepipeline[env.branch].arn}/*" if env.name == each.key]
    )
  }
  statement {
    effect = "Allow"

    actions = [
      "ssm:GetParametersByPath",
      "ssm:GetParameters"
    ]

    resources = [aws_ssm_parameter.build_environment[each.key].arn]
  }
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

resource "aws_iam_role_policy" "codebuild_build" {
  for_each = var.build_environments_names

  name   = "${var.project_name}-${each.key}-codebuild-build-policy"
  role   = aws_iam_role.codebuild_build[each.key].id
  policy = data.aws_iam_policy_document.codebuild_build[each.key].json
}

resource "aws_codebuild_project" "build" {
  for_each = var.build_environments_names

  name         = "${var.project_name}-${each.value}-codebuild-build"
  service_role = aws_iam_role.codebuild_build[each.key].arn

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

    environment_variable {
      name  = "NEXT_PUBLIC_BUILD_ENVIRONMENT"
      type  = "PARAMETER_STORE"
      value = "${var.project_name}-${each.key}-build-environment"
    }
  }
}

# Test
resource "aws_iam_role" "codebuild_test" {
  for_each = var.build_environments_names

  name               = "${var.project_name}-${each.key}-codebuild-test-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}

data "aws_iam_policy_document" "codebuild_test" {
  for_each = var.build_environments_names

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:PutObjectAcl",
      "s3:DeleteObject"
    ]

    resources = concat(
      [for env in var.build_environments : aws_s3_bucket.codepipeline[env.branch].arn if env.name == each.key],
      [for env in var.build_environments : "${aws_s3_bucket.codepipeline[env.branch].arn}/*" if env.name == each.key]
    )
  }
  statement {
    effect = "Allow"

    actions = [
      "ssm:GetParametersByPath",
      "ssm:GetParameters"
    ]

    resources = [aws_ssm_parameter.build_environment[each.key].arn]
  }
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

resource "aws_iam_role_policy" "codebuild_test" {
  for_each = var.build_environments_names

  name   = "${var.project_name}-${each.key}-codebuild-test-policy"
  role   = aws_iam_role.codebuild_test[each.key].id
  policy = data.aws_iam_policy_document.codebuild_test[each.key].json
}

resource "aws_codebuild_project" "test" {
  for_each = var.build_environments_names

  name         = "${var.project_name}-${each.value}-codebuild-test"
  service_role = aws_iam_role.codebuild_test[each.key].arn

  artifacts {
    type = "CODEPIPELINE"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec/test.yml"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    type         = "LINUX_CONTAINER"
    image        = "aws/codebuild/standard:7.0"

    environment_variable {
      name  = "NEXT_PUBLIC_BUILD_ENVIRONMENT"
      type  = "PARAMETER_STORE"
      value = "${var.project_name}-${each.key}-build-environment"
    }
  }
}

# Deploy
resource "aws_iam_role" "codebuild_deploy" {
  for_each = var.build_environments_names

  name               = "${var.project_name}-${each.key}-codebuild-deploy-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}

data "aws_iam_policy_document" "codebuild_deploy" {
  for_each = var.build_environments_names

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:PutObjectAcl",
      "s3:DeleteObject"
    ]

    resources = concat(
      [aws_s3_bucket.build[each.key].arn, "${aws_s3_bucket.build[each.key].arn}/*"],
      [for env in var.build_environments : aws_s3_bucket.codepipeline[env.branch].arn if env.name == each.key],
      [for env in var.build_environments : "${aws_s3_bucket.codepipeline[env.branch].arn}/*" if env.name == each.key]
    )
  }

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

resource "aws_iam_role_policy" "codebuild_deploy" {
  for_each = var.build_environments_names

  name   = "${var.project_name}-${each.key}-codebuild-deploy-policy"
  role   = aws_iam_role.codebuild_deploy[each.key].id
  policy = data.aws_iam_policy_document.codebuild_deploy[each.key].json
}

resource "aws_codebuild_project" "deploy" {
  for_each = var.build_environments_names

  name         = "${var.project_name}-${each.value}-codebuild-deploy"
  service_role = aws_iam_role.codebuild_deploy[each.key].arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  source {
    type      = "NO_SOURCE"
    buildspec = <<EOF
      version: 0.2

      phases:
        build:
          commands:
            - aws s3 cp . "s3://${aws_s3_bucket.build[each.value].id}" --recursive --acl=private
            - aws s3 sync . "s3://${aws_s3_bucket.build[each.value].id}" --delete --acl=private
            
    EOF
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    type         = "LINUX_CONTAINER"
    image        = "aws/codebuild/standard:7.0"
  }
}

##############
### Lambda ###
##############
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
resource "aws_iam_role" "lambda" {
  for_each = var.build_environments_names

  name               = "${var.project_name}-${each.key}-invalidate-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "lambda" {
  for_each = var.build_environments_names

  statement {
    effect = "Allow"

    actions = [
      "codepipeline:PutJobSuccessResult",
      "codepipeline:PutJobFailureResult"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "cloudfront:CreateInvalidation"
    ]

    resources = [var.cloudfront_distribution_arns[each.key]]
  }

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

resource "aws_iam_role_policy" "lambda" {
  for_each = var.build_environments_names

  name   = "${var.project_name}-${each.key}-invalidate-lambda-policy"
  role   = aws_iam_role.lambda[each.key].id
  policy = data.aws_iam_policy_document.lambda[each.key].json
}

data "archive_file" "lambda" {
  for_each = var.build_environments_names

  type        = "zip"
  source_file = "lambdas/cloudfront_invalidate/index.mjs"
  output_path = "lambdas/cloudfront_invalidate_${each.key}.zip"
}
resource "aws_lambda_function" "invalidate" {
  for_each = var.build_environments_names

  filename      = data.archive_file.lambda[each.key].output_path
  function_name = "${var.project_name}-${each.key}-cloudfront-invalidate"
  role          = aws_iam_role.lambda[each.key].arn
  handler       = "index.handler"

  source_code_hash = data.archive_file.lambda[each.key].output_base64sha256
  runtime          = "nodejs20.x"

  environment {
    variables = {
      CLOUDFRONT_DISTRIBUTION_ID = var.cloudfront_distribution_ids[each.key]
    }
  }
}

####################
### CodePipeline ###
####################
data "aws_iam_policy_document" "codepipeline_assume_role" {
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
  for_each = local.build_environment_branches

  name               = "${var.project_name}-${each.key}-codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role.json
}

data "aws_iam_policy_document" "codepipeline_policy" {
  for_each = local.build_environment_branches

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:PutObjectAcl",
      "s3:DeleteObject"
    ]

    resources = [
      aws_s3_bucket.codepipeline[each.key].arn,
      "${aws_s3_bucket.codepipeline[each.key].arn}/*"
    ]
  }

  statement {
    effect = "Allow"

    actions = ["codestar-connections:UseConnection"]

    resources = [aws_codestarconnections_connection.website.arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]

    resources = concat(
      [for env in var.build_environments : aws_codebuild_project.build[env.name].arn if env.branch == each.key],
      [for env in var.build_environments : aws_codebuild_project.test[env.name].arn if env.branch == each.key],
      [for env in var.build_environments : aws_codebuild_project.deploy[env.name].arn if env.branch == each.key],
    )
  }

  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction"
    ]

    resources = [for env in var.build_environments : aws_lambda_function.invalidate[env.name].arn if env.branch == each.key]
  }

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
  for_each = local.build_environment_branches

  name   = "${var.project_name}-${each.key}-codepipeline-policy"
  role   = aws_iam_role.codepipeline_role[each.key].id
  policy = data.aws_iam_policy_document.codepipeline_policy[each.key].json
}

resource "aws_codepipeline" "website" {
  for_each = local.build_environment_branches

  name     = "${var.project_name}-${each.value}-codepipeline"
  role_arn = aws_iam_role.codepipeline_role[each.key].arn

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

      dynamic "action" {
        for_each = contains(local.build_environment_requires_approval, stage.value.name) ? [1] : []
        content {
          name      = "Approval"
          category  = "Approval"
          owner     = "AWS"
          provider  = "Manual"
          version   = "1"
          run_order = 1
        }
      }

      action {
        name             = "Build"
        category         = "Build"
        owner            = "AWS"
        provider         = "CodeBuild"
        version          = "1"
        input_artifacts  = ["source_output"]
        output_artifacts = ["${stage.value.name}-build_source_output"]
        run_order        = 2

        configuration = {
          ProjectName = aws_codebuild_project.build[stage.value.name].name
        }
      }

      action {
        name             = "Test"
        category         = "Test"
        owner            = "AWS"
        provider         = "CodeBuild"
        version          = "1"
        input_artifacts  = ["${stage.value.name}-build_source_output"]
        output_artifacts = ["${stage.value.name}-build_output"]
        run_order        = 3

        configuration = {
          ProjectName = aws_codebuild_project.test[stage.value.name].name
        }
      }

      action {
        name            = "Deploy"
        category        = "Build"
        owner           = "AWS"
        provider        = "CodeBuild"
        version         = "1"
        input_artifacts = ["${stage.value.name}-build_output"]
        run_order       = 4

        configuration = {
          ProjectName = aws_codebuild_project.deploy[stage.value.name].name
        }
      }

      action {
        name      = "Invalidate"
        category  = "Invoke"
        owner     = "AWS"
        provider  = "Lambda"
        version   = "1"
        run_order = 5

        configuration = {
          FunctionName = "${var.project_name}-${stage.value.name}-cloudfront-invalidate"
        }
      }
    }
  }
}
