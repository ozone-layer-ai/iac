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
