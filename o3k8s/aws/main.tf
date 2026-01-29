resource "aws_eip" "cp_eips" {
  count = var.eip_count
  domain = "vpc"

  tags = {
    Name                    = "${var.cluster}-${count.index + 1}"
    eip-allocation-bypass   = ""
  }
}
