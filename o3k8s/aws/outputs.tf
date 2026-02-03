output "cp_eips" {
  value = [for eip in aws_eip.cp_eips : eip]
}

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