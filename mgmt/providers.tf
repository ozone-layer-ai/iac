# 834jes-z22JTuwcGNdtyuqKH00rHkfcfozpt4wM7
terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
    env = {
      source = "tchupp/env"
    }
  }
}

# CLOUDFLARE_API_TOKEN
provider "cloudflare" {}


# module.cloudflare.cloudflare_managed_transforms.managed_transforms will be destroyed
# (because cloudflare_managed_transforms.managed_transforms is not in configuration)
# - resource "cloudflare_managed_transforms" "managed_transforms" {
# - id                       = "fd5273774a08326da857572c6f9033b2" -> null
# - managed_request_headers  = [
# - {
# - enabled = true -> null
# - id      = "add_visitor_location_headers" -> null
# },
# ] -> null
# - managed_response_headers = [
# - {
# - enabled = true -> null
# - id      = "remove_x-powered-by_header" -> null
# },
# ] -> null
# - zone_id                  = "fd5273774a08326da857572c6f9033b2" -> null
# }