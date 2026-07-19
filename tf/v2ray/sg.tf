locals {
  sg_count          = ceil(length(var.v2ray_allowed_cidrs) / 60)
  v2ray_cidr_chunks = chunklist(var.v2ray_allowed_cidrs, 60)
}

resource "aws_security_group" "ssh" {
  name_prefix = "ssh"
  description = "SSH access"
  vpc_id      = aws_default_vpc.default.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ingress_ssh" {
  description       = "SSH from ${var.ssh_allowed_cidrs[0]}"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.ssh_allowed_cidrs
  security_group_id = aws_security_group.ssh.id
}

resource "aws_security_group_rule" "egress_all" {
  description       = "Allow all traffic out"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ssh.id
}

resource "aws_security_group" "v2ray" {
  count = local.sg_count
  name_prefix = "v2ray"
  description = "v2ray traffic (group ${count.index + 1})"
  vpc_id      = aws_default_vpc.default.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ingress_v2ray" {
  count = local.sg_count
  description       = "V2Ray ingress"
  type              = "ingress"
  from_port         = var.v2ray_port
  to_port           = var.v2ray_port
  protocol          = "tcp"
  cidr_blocks       = local.v2ray_cidr_chunks[count.index]
  security_group_id = aws_security_group.v2ray[count.index].id
}
