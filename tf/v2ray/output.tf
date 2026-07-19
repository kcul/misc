output "v2ray_public_ip" {
  value = "${aws_eip.v2ray.public_ip} (${var.region})"
}

output "mosh_cli" {
  value = "mosh --ssh='ssh -i ~/.ssh/kcul_ed25519' ec2-user@${aws_eip.v2ray.public_ip}"
}
