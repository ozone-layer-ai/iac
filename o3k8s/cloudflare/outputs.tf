output "tunnel_token" {
  value = data.cloudflare_zero_trust_tunnel_cloudflared_token.cf_tunnel_token.token
}

locals {
  cluster_access_url_apex=replace(cloudflare_dns_record.this.name, data.cloudflare_zone.this.name, "")
}

output "cluster_access_url" {
  value = "${local.cluster_access_url_apex}${data.cloudflare_zone.this.name}"
}