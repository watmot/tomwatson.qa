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

provider "aws" {
  region = "eu-west-2"
  default_tags {
    tags = {
      Project       = "tomwatsonqa-website"
      ProvisionedBy = "terraform"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "use1"
  default_tags {
    tags = {
      Project       = "tomwatsonqa-website"
      ProvisionedBy = "terraform"
    }
  }
}
