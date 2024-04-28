output "v2ray_public_ip" {
  value = aws_eip.v2ray.public_ip
}

output "v2ray_instance_id" {
  value = aws_instance.v2ray.id
}

output "vpc_id" {
  value = aws_default_vpc.default.id
}

output "igw" {
  value = data.aws_internet_gateway.default.id
}

#output "my_current_ip" {
#  value = data.external.current_ip
#}
