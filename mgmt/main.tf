module "cloudflare" {
  source = "./cloudflare"

  account_id = var.cf_account_id
  tunnel_name = "ozone-layer-ai"
  ingress_service = "http://traefik.traefik:80"
}