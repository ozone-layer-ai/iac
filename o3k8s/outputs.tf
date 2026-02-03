output "cp_eips" {
  value = module.aws.cp_eips
}

output "tunnel_token" {
  value = module.cloudflare.tunnel_token
}

output "cluster_access_url" {
  value = module.cloudflare.cluster_access_url
}

output "vpc_id" {
  value = module.aws.vpc_id
}

output "vpc_default_sg_id" {
  value = module.aws.vpc_default_sg_id
}

output "private_subnets" {
  value = module.aws.private_subnets
}

output "public_subnets" {
  value = module.aws.public_subnets
}