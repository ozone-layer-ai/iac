locals {
  aws_azs      = slice(data.aws_availability_zones.available.names, 0, 3)

#   aws_wireguard_base_cidr = cidrsubnet(var.aws_vpc_cidr, 8, 1)
#   aws_wireguard_subnets = [
#     for k, az in local.aws_azs :
#     cidrsubnet(local.aws_wireguard_base_cidr, 2, k)
#   ]
#   aws_wireguard_subnet_ids = [
#     for s in module.vpc.private_subnet_objects :
#     s.id if contains(local.aws_wireguard_subnets, s.cidr_block)
#   ]

  aws_worker_base_cidr = cidrsubnet(var.aws_vpc_cidr, 8, 10)
  aws_worker_subnets = [
    for k, az in local.aws_azs :
    cidrsubnet(local.aws_worker_base_cidr, 2, k)
  ]
  aws_worker_subnet_ids = [
    for s in module.vpc.private_subnet_objects :
    s.id if contains(local.aws_worker_subnets, s.cidr_block)
  ]

  aws_public_base_cidr = cidrsubnet(var.aws_vpc_cidr, 8, 20)
  aws_public_subnets = [
    for k, az in local.aws_azs :
    cidrsubnet(local.aws_public_base_cidr, 2, k)
  ]
  aws_public_subnet_ids = [
    for s in module.vpc.public_subnet_objects :
    s.id if contains(local.aws_public_subnets, s.cidr_block)
  ]

  vpc_tags = {
    Name             = "${var.cluster}-vpc"
    GuardDutyManaged = false
    flowlog          = "ALL"
    Scope            = "Public"
  }
}

module "vpc" {
  providers = {
    aws = aws.worker
  }

  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.0"

  name = local.vpc_tags.Name
  cidr = var.aws_vpc_cidr

  azs             = local.aws_azs
  private_subnets = concat(local.aws_worker_subnets)
  public_subnets  = local.aws_public_subnets

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = true

  nat_eip_tags = {
    eip-allocation-bypass = ""
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.vpc_tags

}