resource "aws_iam_role" "v2ray" {
  name_prefix = "v2ray-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" ]

  tags = {
    Name = "v2ray"
  }
}

resource "aws_iam_instance_profile" "v2ray" {
  name_prefix = "v2ray-role"
  role = aws_iam_role.v2ray.name
}
