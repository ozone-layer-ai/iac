module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.5.0"

  name = local.cluster_name
  cidr = var.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs_public_private_subnets : cidrsubnet(var.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs_public_private_subnets : cidrsubnet(var.vpc_cidr, 8, k + 48)]

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