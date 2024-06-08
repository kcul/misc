resource "aws_eip" "outline" {
  instance = aws_instance.outline.id
  domain   = "vpc"
}

resource "aws_instance" "outline" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = local.instance_type
  subnet_id              = aws_subnet.outline.id
  key_name               = aws_key_pair.kcul.key_name
  vpc_security_group_ids = [aws_security_group.outline.id]
  iam_instance_profile   = aws_iam_instance_profile.outline.name
  user_data              = file("files/user-data.txt")
  ebs_optimized          = true
  monitoring             = true
  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "optional"
    instance_metadata_tags      = "enabled"
  }
  tags = {
    "Name" = "outline"
  }
  volume_tags = {
    "Name" = "outline"
  }
  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_size           = 8
    volume_type           = "gp3"
  }
  #
  # lifecycle {
  #   ignore_changes = [user_data]
  # }
}

