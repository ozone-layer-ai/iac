resource "cloudflare_dns_record" "this" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = var.cluster
  content = "${cloudflare_zero_trust_tunnel_cloudflared.cf_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}