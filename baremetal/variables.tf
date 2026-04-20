locals {
  env = "Staging"
}

variable "vpc_id" {
  default = "vpc-0aed093b41e29ce36"
}

variable "subnet_id" {
  default = "subnet-09ca236cbb4cf77fe"
}

variable "iam_instance_profile_name" {
  default = "EC2forSSMRole"
}

variable "force_recreate_worker_vms" {
  description = "When true, recreates worker VMs and their qcow2 disks on host bootstrap to guarantee clean node storage."
  type        = bool
  default     = true
}
