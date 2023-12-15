locals {
  project_name = "tomwatsonqa-website"
  build_environments = ["dev", "test", "staging", "production"]
}

resource "aws_s3_bucket" "build" {
  for_each = toset(local.build_environments)

  bucket = "${local.project_name}-build-${each.key}"
}