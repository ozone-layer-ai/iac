terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.19.0"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "5.16"
    }
    env = {
      source = "tchupp/env"
    }
  }
}

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
# AWS_REGION
provider "aws" {}

# CLOUDFLARE_API_TOKEN
provider "cloudflare" {}
