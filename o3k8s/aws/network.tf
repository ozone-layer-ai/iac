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
    Name         = "${var.cluster}-vpc"
#     Team         = var.team
    flowlog      = "ALL"
    Scope        = "Public"
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

# only used for clean destruction of VPC (due to lingering resources created automatically by the API).
# resource "null_resource" "cleanup_vpc_endpoints_enis_sgs" {
#   triggers = {
#     vpc_id    = module.vpc.vpc_id
#   }
#
#   provisioner "local-exec" {
#     when    = destroy
#     interpreter = ["/bin/bash", "-c"]
#     command = <<EOT
# #!/bin/bash
# set -euo pipefail
#
# # Install AWS CLI in user space (no root required)
# echo "Checking and installing required CLI tools..."
#
# # Function to check if a command exists
# command_exists() {
#     command -v "$1" &> /dev/null
# }
#
# # Set up local bin directory
# mkdir -p "$HOME/.local/bin"
# export PATH="$HOME/.local/bin:$PATH"
#
# # Install AWS CLI if not present
# if ! command_exists aws; then
#     echo "AWS CLI not found. Installing via pip..."
#
#     # Check if pip is available
#     if command_exists pip3; then
#         PIP_CMD="pip3"
#     elif command_exists pip; then
#         PIP_CMD="pip"
#     elif command_exists python3; then
#         # Try to use python3 -m pip
#         if python3 -m pip --version &> /dev/null; then
#             PIP_CMD="python3 -m pip"
#         else
#             echo "ERROR: pip not available. Cannot install AWS CLI."
#             echo "Available commands:"
#             command -v python3 && python3 --version || echo "  python3: not found"
#             command -v python && python --version || echo "  python: not found"
#             exit 1
#         fi
#     else
#         echo "ERROR: Neither pip nor python3 found. Cannot install AWS CLI."
#         exit 1
#     fi
#
#     echo "Installing AWS CLI using: $PIP_CMD"
#
#     # Install awscli to user directory
#     $PIP_CMD install --user awscli
#
#     # Add Python user bin to PATH if not already there
#     PYTHON_USER_BIN=$(python3 -c "import site; print(site.USER_BASE + '/bin')" 2>/dev/null || echo "$HOME/.local/bin")
#     export PATH="$PYTHON_USER_BIN:$PATH"
#
#     echo "AWS CLI installed successfully"
# else
#     echo "AWS CLI already installed: $(aws --version)"
# fi
#
# # Verify AWS CLI is accessible
# if ! command_exists aws; then
#     echo "ERROR: AWS CLI installation failed or not in PATH"
#     echo "PATH: $PATH"
#     echo "Checking common locations:"
#     ls -la "$HOME/.local/bin/" 2>/dev/null || echo "  $HOME/.local/bin/ not found"
#     ls -la "$(python3 -c "import site; print(site.USER_BASE + '/bin')" 2>/dev/null)" 2>/dev/null || echo "  Python user bin not found"
#     exit 1
# fi
#
# echo "All required tools are available."
# echo "AWS CLI version: $(aws --version)"
# echo "----------------------------------------"
#
# # Original script starts here
# VPC_ID="${self.triggers.vpc_id}"
# echo "Starting cleanup for VPC $VPC_ID..."
#
# delete_and_wait_for_vpce() {
#   local vpce_id="$1"
#   echo "Deleting VPC Endpoint $vpce_id..."
#   aws ec2 delete-vpc-endpoints --vpc-endpoint-ids "$vpce_id"
#   echo "Waiting for $vpce_id to be fully deleted..."
#   for i in {1..20}; do
#     status=$(aws ec2 describe-vpc-endpoints --vpc-endpoint-ids "$vpce_id" \
#       --query 'VpcEndpoints[0].State' --output text 2>/dev/null || echo "deleted")
#     if [[ "$status" == "deleted" || "$status" == "None" || "$status" == "null" ]]; then
#       echo "$vpce_id deleted."
#       break
#     else
#       echo "$vpce_id still in state: $status"
#       sleep 5
#     fi
#   done
# }
#
# # 1. Delete all VPC Endpoints
# for vpce in $(aws ec2 describe-vpc-endpoints \
#   --filters Name=vpc-id,Values="$VPC_ID" \
#   --query 'VpcEndpoints[*].VpcEndpointId' \
#   --output text); do
#   delete_and_wait_for_vpce "$vpce"
# done
#
# # 2. Wait for remaining ENIs in the VPC to be gone
# echo "Waiting for remaining ENIs to disappear from VPC $VPC_ID..."
# for i in {1..30}; do
#   eni_count=$(aws ec2 describe-network-interfaces \
#     --filters Name=vpc-id,Values="$VPC_ID" \
#     --query 'length(NetworkInterfaces)' --output text)
#   if [[ "$eni_count" -eq 0 ]]; then
#     echo "All ENIs removed from VPC."
#     break
#   else
#     echo "Still $eni_count ENIs present... waiting..."
#     sleep 5
#   fi
# done
#
# # 3. Delete all non-default security groups in the VPC
# echo "Deleting all non-default security groups in VPC $VPC_ID..."
# for sg_id in $(aws ec2 describe-security-groups \
#     --filters Name=vpc-id,Values="$VPC_ID" \
#     --query 'SecurityGroups[?GroupName!=`default`].GroupId' \
#     --output text); do
#   echo "Attempting to delete security group $sg_id..."
#   aws ec2 delete-security-group --group-id "$sg_id" || echo "Could not delete $sg_id (may be in use or referenced elsewhere)."
# done
#
# echo "Cleanup complete."
# EOT
#   }
#
#   depends_on = [
#     module.vpc,
#     module.vpc.private_subnet_objects
#   ]
# }


