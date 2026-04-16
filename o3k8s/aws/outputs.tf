output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_default_sg_id" {
  value = module.vpc.default_security_group_id
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "nat_gw_ips" {
  value = module.vpc.nat_public_ips
}

output "ami_id" {
  value = data.aws_ssm_parameter.selected_ami.value
  sensitive = true
}