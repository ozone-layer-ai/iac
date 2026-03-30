terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
  }
}

# CLOUDFLARE_API_TOKEN
provider "cloudflare" {}