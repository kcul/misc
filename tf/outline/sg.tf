resource "aws_security_group" "outline" {
  name_prefix = "outline"
  description = "outline traffic"
  vpc_id      = aws_default_vpc.default.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ingress_local_all" {
  description       = "allow all from local"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["110.87.129.7/32"]
  security_group_id = aws_security_group.outline.id
}

resource "aws_security_group_rule" "egress_all" {
  description       = "Allow all traffic out"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.outline.id
}
