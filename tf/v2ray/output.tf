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

output "v2ray_sg_count" {
  value = local.sg_count
}

output "v2ray_security_group_ids" {
  value = aws_security_group.v2ray[*].id
}

output "ssh_security_group_id" {
  value = aws_security_group.ssh.id
}

output "mosh_cli" {
  value = "mosh --ssh='ssh -i ~/.ssh/kcul_ed25519' ec2-user@${aws_eip.v2ray.public_ip}"
}
