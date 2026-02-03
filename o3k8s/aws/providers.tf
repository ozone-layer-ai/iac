provider "aws" {
  alias = "worker"
  region = var.worker_region
}