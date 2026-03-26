resource "aws_eip" "ironic_eips" {
  domain = "vpc"

  tags = {
    Name = "ironic"
    eip-allocation-bypass = ""
  }
}