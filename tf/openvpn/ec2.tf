data "aws_ami" "al2023_arm64" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-arm64"]
  }
  filter {
    name   = "architecture"
    values = ["arm64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "openvpn" {
  ami           = data.aws_ami.al2023_arm64.id
  instance_type = "t4g.micro"
  subnet_id              = aws_subnet.openvpn.id
  key_name               = aws_key_pair.kcul.key_name
  vpc_security_group_ids = [aws_security_group.openvpn.id]
  iam_instance_profile = aws_iam_instance_profile.openvpn.name
  user_data = file("files/user-data.txt")
  ebs_optimized = true
  monitoring = true
  metadata_options  {
    http_endpoint = "enabled"
    http_put_response_hop_limit = 1
    http_tokens = "optional"
    instance_metadata_tags = "enabled"
  }
  tags = {
    "Name"             = "openvpn"
  }
  volume_tags = {
    "Name"             = "openvpn"
  }
  root_block_device {
      delete_on_termination = true
      encrypted = true
      volume_size = 8
      volume_type = "gp3"
  }
  lifecycle {
    ignore_changes = [user_data]
  }
}

resource "aws_eip" "openvpn" {
  domain = vpc
  depend_on = [aws_internet_gateway.default]
}

resource "aws_eip_association" "openvpn" {
  instance_id   = aws_instance.openvpn.id
  allocation_id = aws_eip.openvpn.id
}
