locals {
  vpc_endpoints = {
    "eks-ebs-ep" = {
      service_name        = "com.amazonaws.us-east-2.ebs"
      private_dns_enabled = false
    }
    "eks-sts-ep" = {
      service_name        = "com.amazonaws.us-east-2.sts"
      private_dns_enabled = false
    }
    "ec2" = {
      service_name        = "com.amazonaws.us-east-2.ec2"
      private_dns_enabled = false
    }
  }
}

resource "aws_vpc_endpoint" "endpoints" {
  for_each         = local.vpc_endpoints
  vpc_id            = module.vpc.vpc_id
  service_name      = each.value.service_name
  vpc_endpoint_type = "Interface"
  service_region    = lookup(each.value, "region", data.env_variable.aws_region.value)

  subnet_ids = [
    module.vpc.private_subnets[0],
    module.vpc.private_subnets[1],
    module.vpc.private_subnets[2]
  ]
  security_group_ids = [
    module.eks.cluster_security_group_id,
    module.eks.cluster_primary_security_group_id,
    module.eks.node_security_group_id
  ]

  tags = {
    Name       = each.key,
    deployedBy = var.deployedBy
  }

  private_dns_enabled = each.value.private_dns_enabled
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.us-east-2.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = module.vpc.private_route_table_ids
}