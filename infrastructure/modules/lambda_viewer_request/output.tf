output "lambda_arn" {
  value = aws_lambda_function.lambda.qualified_arn
}

output "basic_auth_credentials" {
  value = random_string.basic_auth_credentials.result
}
