variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "environment" {
  description = "Environment name"
}

variable "team" {
  description = "Owning team name"
}

variable "deployedBy" {
  description = "Enter your email address"
}

variable "iam_role_names" {
  description = "List of IAM role names to grant viewer access to the EKS cluster"
  type        = list(string)
}

variable "iam_user_names" {
  description = "List of IAM user names to grant viewer access to the EKS cluster"
  type        = list(string)
}

variable "dns_zones" {
  description = "Map of DNS zone configurations, including name and privacy setting."
  type = map(object({
    name    = string
    private = bool
  }))
  default = {} # Or provide defaults if suitable
}

variable "cluster_version" {
  description = "The version of the cluster"
  type        = string
  default     = "1.34"
}