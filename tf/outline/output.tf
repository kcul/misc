output "outline_public_ip" {
  value = aws_eip.outline.public_ip
}

output "outline_instance_id" {
  value = aws_instance.outline.id
}

output "vpc_id" {
  value = aws_default_vpc.default.id
}

# output "igw" {
#   value = data.aws_internet_gateway.default.id
# }
#
# output "my_current_ip" {
#   value = data.external.current_ip
# }
