output "tunnel_token" {
  value = data.cloudflare_zero_trust_tunnel_cloudflared_token.cf_tunnel_token.token
}

output "tunnel_dns" {
  value = "${cloudflare_zero_trust_tunnel_cloudflared.cf_tunnel.id}.cfargotunnel.com"
}