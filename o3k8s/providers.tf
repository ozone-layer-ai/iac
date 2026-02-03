terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.28.0"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "5.16"
    }
    env = {
      source = "tchupp/env"
    }
    null = {
      source = "hashicorp/null"
      version = "3.2.4"
    }
  }
}

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
# AWS_REGION
provider "aws" {}

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
provider "aws" {
  alias = "worker"
  region = var.worker_region
}

# CLOUDFLARE_API_TOKEN
provider "cloudflare" {}
