##############
### Lambda ###
##############

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_lambda_function" "lambda" {
  filename         = var.output_path
  function_name    = var.function_name
  role             = var.iam_role
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  publish          = true
  source_code_hash = var.source_code_hash
}
