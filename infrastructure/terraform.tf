terraform {
  cloud {
    organization = "tomwatsonqa"

    workspaces {
      name = "tomwatsonqa-website"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}