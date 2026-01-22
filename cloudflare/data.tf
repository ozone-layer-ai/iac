data "cloudflare_zero_trust_tunnel_cloudflared_token" "cf_tunnel_token" {
  account_id = cloudflare_zero_trust_tunnel_cloudflared.cf_tunnel.account_id
  tunnel_id = cloudflare_zero_trust_tunnel_cloudflared.cf_tunnel.id
}

data "cloudflare_zone" "this" {
  filter = {
    name = var.domain
  }
}