output "v2ray_public_ip" {
  value = "${aws_eip.v2ray.public_ip} (${local.region})"
}
