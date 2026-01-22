output "tunnel_token" {
  value = data.cloudflare_zero_trust_tunnel_cloudflared_token.cf_tunnel_token.token
}

output "cluster_access_url" {
  value = "${cloudflare_dns_record.console.name}.${data.cloudflare_zone.this.name}"
  sensitive = true
}