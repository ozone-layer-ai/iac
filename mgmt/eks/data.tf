data "aws_availability_zones" "available" {
  # Exclude local zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_iam_role" "roles" {
  for_each = toset(var.iam_role_names)
  name     = each.value
}

data "aws_iam_user" "users" {
  for_each = toset(var.iam_user_names)
  user_name = each.value
}

data "env_variable" "aws_region" {
  name = "AWS_REGION"
}

locals {
  cluster_name         = "${var.team}-${var.environment}-${data.env_variable.aws_region.value}"
  azs      = data.aws_availability_zones.available.names
  azs_public_private_subnets      = slice(data.aws_availability_zones.available.names, 0, 3)

  eks_tags      = {
    Name         = local.cluster_name
    Team         = var.team
    DeployedBy   = var.deployedBy
    DeployMethod = "terraform"
    createdby    = var.deployedBy
    Environment  = var.environment
  }

  vpc_tags = {
    Name         = local.cluster_name
    Team         = var.team
    DeployedBy   = var.deployedBy
    DeployMethod = "terraform"
    createdby    = var.deployedBy
    Environment  = var.environment
    flowlog      = "ALL"
    Scope        = "Public"
  }

  access_entries_adminviewers = tomap(
    merge(
      {
        for role_name, role_data in data.aws_iam_role.roles : role_name => {
        kubernetes_groups = []
        principal_arn     = role_data.arn
        type              = "STANDARD"
        policy_associations = {
          cluster = {
            policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      }
      },
      {
        for user_name, user_data in data.aws_iam_user.users : user_name => {
        kubernetes_groups = []
        principal_arn     = user_data.arn
        type              = "STANDARD"
        policy_associations = {
          cluster = {
            policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      }
      }
    )
  )

  access_entries = merge(local.access_entries_adminviewers)
}