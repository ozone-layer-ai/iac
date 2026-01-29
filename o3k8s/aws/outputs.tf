output "cp_eips" {
  value = [for eip in aws_eip.cp_eips : eip]
}