resource "aws_security_group" "openvpn" {
  name_prefix        = "openvpn"
  description = "openvpn traffic"
  vpc_id      = aws_default_vpc.default.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ingress_ssh" {
  description       = "allow ssh from local"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${local.my_ip}/32"]
  security_group_id = aws_security_group.openvpn.id
}

resource "aws_security_group_rule" "ingress_http" {
  description       = "allow UDP 1194 in"
  type              = "ingress"
  from_port         = 1194
  to_port           = 1194
  protocol          = "udp"
  cidr_blocks       = ["${local.my_ip}/32"]
  security_group_id = aws_security_group.openvpn.id
}

resource "aws_security_group_rule" "egress_all" {
  description       = "Allow all traffic out"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.openvpn.id
}
