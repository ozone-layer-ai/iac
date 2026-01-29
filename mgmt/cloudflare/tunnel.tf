resource "random_password" "tunnel_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "cf_tunnel" {
  account_id = var.account_id
  name       = var.tunnel_name
  tunnel_secret     = base64sha256(random_password.tunnel_password.result)
  config_src = "cloudflare"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "config" {
  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.cf_tunnel.id
  source     = "cloudflare"

  config = {
    ingress = [
      {
        hostname = "console.ozonelayerai.com"
        service = "http://traefik.traefik:80"
      },
      {
        service = "https://traefik.traefik:6443"
        origin_request = {
          no_tls_verify = true
        }
      }
    ]
  }
}