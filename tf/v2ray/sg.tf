resource "aws_security_group" "v2ray" {
  name_prefix        = "v2ray"
  description = "v2ray traffic"
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
  cidr_blocks       = ["120.35.235.91/32"]
  security_group_id = aws_security_group.v2ray.id
}

resource "aws_security_group_rule" "ingress_http" {
  description       = "allow 80 in"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.v2ray.id
}

resource "aws_security_group_rule" "ingress_udp" {
  description       = "allow 80 in"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.v2ray.id
}


resource "aws_security_group_rule" "egress_all" {
  description       = "Allow all traffic out"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.v2ray.id
}
