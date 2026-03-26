output "ocp_cluster_cadata" {
  description = "To be used when configuring ArgoCD cluster data"
  value = module.eks.cluster_certificate_authority_data
}

output "ocp_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "ocp_cluster_name" {
  value = module.eks.cluster_name
  sensitive = true
}

output "ebs_iam_role_arn" {
  value = module.ebs_csi_irsa_role.iam_role_arn
}

output "external_dns_iam_role_arn" {
  value = aws_iam_role.external_dns_service_account.arn
}

output "terraform_operator_iam_role_arn" {
  value = aws_iam_role.terraform_operator_service_account.arn
}

output "vpc_id" {
  value = module.vpc.vpc_id
}