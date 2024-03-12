#############################
### Viewer Request Lambda ###
#############################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Secrets Manager
resource "random_string" "basic_auth_credentials" {
  keepers = {
    version = 1
  }

  length = 20
}

resource "aws_secretsmanager_secret" "basic_auth_credentials" {
  name = "${var.project_name}-${var.build_environment}-basic-auth-credentials"
}

resource "aws_secretsmanager_secret_version" "basic_auth_credentials" {
  secret_id     = aws_secretsmanager_secret.basic_auth_credentials.id
  secret_string = "${var.build_environment}:${random_string.basic_auth_credentials.result}"
}

# IAM
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${var.project_name}-${var.build_environment}-viewer-request-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "lambda_policy" {
  # Secrets Manager
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [aws_secretsmanager_secret_version.basic_auth_credentials.arn]
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

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "${var.project_name}-viewer-request-lambda-policy"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}

# Lambda

data "archive_file" "lambda" {
  type = "zip"
  source {
    content = templatefile("./lambdas/viewer_request/index.tpl", {
      BASIC_AUTH_ENABLED   = var.basic_auth_enabled
      BASIC_AUTH_SECRET_ID = aws_secretsmanager_secret_version.basic_auth_credentials.arn
    })
    filename = "index.mjs"
  }
  output_path = "lambdas/viewer_request_${var.build_environment}.zip"
}


resource "aws_lambda_function" "lambda" {
  filename         = data.archive_file.lambda.output_path
  function_name    = var.function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  publish          = true
  source_code_hash = data.archive_file.lambda.output_base64sha256
}
