module "ebs_csi_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name             = "${local.cluster_name}-ebs-csi-kmj"
  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

# Replace the module with this:
module "aws_load_balancer_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "aws-load-balancer-controller-kmj"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

################################################################################
# EKS Module
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.8.0"

  name                   = local.cluster_name
  kubernetes_version     = var.cluster_version
  endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true
  access_entries                           = local.access_entries
  authentication_mode                      = "API_AND_CONFIG_MAP"

  compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  # EKS Addons
  addons = {
    coredns = {}
    kube-proxy = {}
    eks-pod-identity-agent = {}
    vpc-cni = {}
    metrics-server = {}
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  openid_connect_audiences = ["sts-assume", "sts.amazonaws.com", "kuberentes.default.svc.cluster.local", "https://kuberentes.default.svc.cluster.local"]

  tags = local.eks_tags
}