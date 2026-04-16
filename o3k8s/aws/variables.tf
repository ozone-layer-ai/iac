variable "cluster" {}

variable "aws_vpc_cidr" {
  default = "10.0.0.0/16" # this is the default for AWS VPCs
}

variable "dlami_ssm_path" {
  type    = string
  default = "/aws/service/deeplearning/ami/x86_64/oss-nvidia-driver-gpu-pytorch-2.7-amazon-linux-2023/latest/ami-id"
}