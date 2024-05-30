# Region
provider "aws" {
  region = "ap-northeast-3"
}
data "aws_region" "current" {}

# VPC
resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
}

# Subnet
resource "aws_subnet" "public_subnet_1a" {
  vpc_id                  = aws_vpc.this.id
  availability_zone       = format("%s%s", data.aws_region.current.name, "a")
  cidr_block              = aws_vpc.this.cidr_block
  map_public_ip_on_launch = true
}

# Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.this.id
}

# Route Table Association
resource "aws_route_table_association" "public_rt_1a" {
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public_subnet_1a.id
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
}

# Route
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Security Group
resource "aws_security_group" "this" {
  vpc_id = aws_vpc.this.id
  name   = "pg-setup-test-security-group"
}

# Security Group Ingress
resource "aws_vpc_security_group_ingress_rule" "allow_tcp" {
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  security_group_id = aws_security_group.this.id
}
resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  security_group_id = aws_security_group.this.id
}

# Security Group Egress
resource "aws_vpc_security_group_egress_rule" "allow_all" {
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  security_group_id = aws_security_group.this.id
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "architecture"
    values = ["arm64"]
  }
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*"]
  }
}

# EC2
resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t4g.small"
  key_name                    = "wireguard-ec2"
  subnet_id                   = aws_subnet.public_subnet_1a.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.this.id]
}
