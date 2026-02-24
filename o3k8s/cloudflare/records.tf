locals {
  tenant_cluster_root = "${var.cluster}-${split("-", var.orgid)[0]}"
}

resource "cloudflare_dns_record" "this" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = local.tenant_cluster_root
  content = "${cloudflare_zero_trust_tunnel_cloudflared.cf_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "metrics" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = "${var.metrics_subdomain}-${local.tenant_cluster_root}"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.cf_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "logs" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = "${var.logs_subdomain}-${local.tenant_cluster_root}"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.cf_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "observe" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = "${var.observe_subdomain}-${local.tenant_cluster_root}"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.cf_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
  ttl     = 1
}
