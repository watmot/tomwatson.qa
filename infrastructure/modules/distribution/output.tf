output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.website.id
}

output "cloudfront_distribution_arn" {
  value = aws_cloudfront_distribution.website.arn
}
