output "cp_eips" {
  value = module.aws.cp_eips
}

output "tunnel_token" {
  value = module.cloudflare.tunnel_token
}

output "cluster_access_url" {
  value = module.cloudflare.cluster_access_url
}