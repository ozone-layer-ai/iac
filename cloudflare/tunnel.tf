resource "random_password" "tunnel_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "cf_tunnel" {
  account_id = data.cloudflare_zone.this.account.id
  name       = var.cluster
  tunnel_secret     = base64sha256(random_password.tunnel_password.result)
  config_src = "cloudflare"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "config" {
  account_id = data.cloudflare_zone.this.account.id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.cf_tunnel.id
  source     = "cloudflare"

  config = {
    warp_routing = {
      enabled = true
    }
    ingress = [
      {
        service = "http://traefik.traefik:80"
      }
    ]
  }
}