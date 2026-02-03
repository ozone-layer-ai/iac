data "aws_availability_zones" "available" {
  provider = aws.worker

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}