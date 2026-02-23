variable "domain" {}

variable "cluster" {}

variable "orgid" {}

variable "metrics_subdomain" {
  default = "metrics"
}

variable "logs_subdomain" {
  default = "logs"
}

variable "observe_subdomain" {
  default = "observe"
}