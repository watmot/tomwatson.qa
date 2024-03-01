output "lambda_arn" {
  value = aws_lambda_function.lambda.qualified_arn
}

output "basic_auth_credentials" {
  value = random_password.basic_auth_credentials.result
}
