module "cloudflare" {
  source = "./cloudflare"

  domain = var.domain
  cluster = var.cluster
}

module "aws" {
  source = "./aws"

  cluster = var.cluster
  eip_count = var.cp_ip_count
}