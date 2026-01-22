resource "random_password" "domain_name" {
  length               = 32
  special              = false
}

resource "cloudflare_dns_record" "console" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = urlencode(random_password.domain_name.result)
  content = "${cloudflare_zero_trust_tunnel_cloudflared.cf_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}