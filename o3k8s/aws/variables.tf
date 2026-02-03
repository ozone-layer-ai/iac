variable "cluster" {}

variable "eip_count" {
  type = number
}

variable "worker_region" {}

variable "aws_vpc_cidr" {
  default = "10.0.0.0/16" # this is the default for AWS VPCs
}