# 1. create new vpc
# 2. create igw for new pvc
# 3. create route table for new vpc
# 4. create one subnet in new vpc

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

data "aws_internet_gateway" "default" {
  filter {
    name   = "attachment.vpc-id"
    values = [aws_default_vpc.default.id]
  }
}

resource "aws_subnet" "outline" {
  vpc_id     = aws_default_vpc.default.id
  cidr_block = cidrsubnet(aws_default_vpc.default.cidr_block, 8, 255)

  tags = {
    Name = "V2ray"
  }
}
