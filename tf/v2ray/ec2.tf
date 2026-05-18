data "aws_ami" "ubuntu" {
  owners      = ["099720109477"]
  most_recent = true

  filter {
      name   = "name"
      values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
      name   = "architecture"
      values = ["x86_64"]
  }

  filter {
      name   = "root-device-type"
      values = ["ebs"]
  }
}

resource "aws_instance" "v2ray" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id              = aws_subnet.v2ray.id
  key_name               = aws_key_pair.kcul.key_name
  vpc_security_group_ids = [aws_security_group.v2ray.id]
  iam_instance_profile = aws_iam_instance_profile.v2ray.name
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
    "Name"             = "v2ray"
  }
  volume_tags = {
    "Name"             = "v2ray"
  }

  root_block_device {
      delete_on_termination = true
      encrypted = true
      volume_size = 8
      volume_type = "gp3"
  }

#  lifecycle {
#    ignore_changes = [user_data]
#  }
}

resource "aws_eip" "v2ray" {
  instance = aws_instance.v2ray.id
  vpc      = true
}
