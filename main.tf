terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.5"
}

provider "aws" {
  region = "us-east-1"
}
# -------------------------
# Production VPC
# -------------------------

resource "aws_vpc" "production" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "production-vpc"
  }
}

resource "aws_subnet" "production_subnet" {
  vpc_id                  = aws_vpc.production.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "production-subnet"
  }
}

resource "aws_internet_gateway" "production_igw" {
  vpc_id = aws_vpc.production.id

  tags = {
    Name = "production-igw"
  }
}

resource "aws_route_table" "production_rt" {
  vpc_id = aws_vpc.production.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.production_igw.id
  }

  route {
    cidr_block         = "10.20.0.0/16"
    transit_gateway_id = aws_ec2_transit_gateway.main.id
  }

  tags = {
    Name = "production-route-table"
  }
}

resource "aws_route_table_association" "production_assoc" {
  subnet_id      = aws_subnet.production_subnet.id
  route_table_id = aws_route_table.production_rt.id
}

# -------------------------
# Development VPC
# -------------------------

resource "aws_vpc" "development" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "development-vpc"
  }
}

resource "aws_subnet" "development_subnet" {
  vpc_id                  = aws_vpc.development.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "development-subnet"
  }
}

resource "aws_internet_gateway" "development_igw" {
  vpc_id = aws_vpc.development.id

  tags = {
    Name = "development-igw"
  }
}

resource "aws_route_table" "development_rt" {
  vpc_id = aws_vpc.development.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.development_igw.id
  }

  route {
    cidr_block         = "10.10.0.0/16"
    transit_gateway_id = aws_ec2_transit_gateway.main.id
  }

  tags = {
    Name = "development-route-table"
  }
}

resource "aws_route_table_association" "development_assoc" {
  subnet_id      = aws_subnet.development_subnet.id
  route_table_id = aws_route_table.development_rt.id
}

# -------------------------
# Security Group
# -------------------------

resource "aws_security_group" "allow_ssh" {
  name        = "allow-ssh"
  description = "Allow SSH and ICMP"
  vpc_id      = aws_vpc.production.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.10.0.0/16", "10.20.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "dev_allow_ssh" {
  name        = "dev-allow-ssh"
  description = "Allow SSH and ICMP"
  vpc_id      = aws_vpc.development.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.10.0.0/16", "10.20.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------
# EC2 Instances
# -------------------------

resource "aws_instance" "production_ec2" {
  count         = 2
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.production_subnet.id

  vpc_security_group_ids = [
    aws_security_group.allow_ssh.id
  ]

  tags = {
    Name = "production-ec2-${count.index + 1}"
  }
}

resource "aws_instance" "development_ec2" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.development_subnet.id

  vpc_security_group_ids = [
    aws_security_group.dev_allow_ssh.id
  ]

  tags = {
    Name = "development-ec2-1"
  }
}

# -------------------------
# Transit Gateway
# -------------------------

resource "aws_ec2_transit_gateway" "main" {
  description = "Transit Gateway connecting production and development VPCs"

  tags = {
    Name = "main-transit-gateway"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "production_attachment" {
  subnet_ids         = [aws_subnet.production_subnet.id]
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.production.id

  tags = {
    Name = "production-tgw-attachment"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "development_attachment" {
  subnet_ids         = [aws_subnet.development_subnet.id]
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.development.id

  tags = {
    Name = "development-tgw-attachment"
  }
}

resource "aws_ec2_transit_gateway_route_table" "main" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = {
    Name = "main-tgw-route-table"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "production_assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.production_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}

resource "aws_ec2_transit_gateway_route_table_association" "development_assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.development_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}

resource "aws_ec2_transit_gateway_route" "to_production" {
  destination_cidr_block         = "10.10.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.production_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}

resource "aws_ec2_transit_gateway_route" "to_development" {
  destination_cidr_block         = "10.20.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.development_attachment.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.main.id
}