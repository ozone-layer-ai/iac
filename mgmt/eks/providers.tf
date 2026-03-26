terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.19.0"
    }
    env = {
      source = "tchupp/env"
      version = "0.0.2"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.38.0"
    }
  }

  # backend "s3" {
  #   bucket = "tf-states-o3"
  #   key = "staging-kmj.tfstate"
  #   region = "us-east-2"
  #   encrypt = true
  # }
}

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
# AWS_REGION
provider "aws" {}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    command     = "aws"
  }
}