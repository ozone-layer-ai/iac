module "cloudflare" {
  source = "./cloudflare"

  domain = var.domain
  cluster = var.cluster
  orgid = var.orgid
}

module "aws" {
  source = "./aws"

  cluster = var.cluster
  eip_count = var.cp_ip_count
  worker_region = var.worker_region
}