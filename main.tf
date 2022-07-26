provider "aws" {
  region = "eu-west-2"
}

# Creating VPC,name, CIDR and Tags
resource "aws_vpc" "dev" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  enable_classiclink   = "false"
  tags = {
    Name = "project1-vpc"
  }
}

# Creating Public Subnets in VPC
resource "aws_subnet" "project1-public1" {
  vpc_id                  = aws_vpc.project1-vpc.id
  cidr_block              = "10.0.0.0/20"
  map_public_ip_on_launch = "true"
  availability_zone       = "eu-west-2a"

  tags = {
    Name = "project-public-1"
  }
}

resource "aws_subnet" "dev-public-2" {
  vpc_id                  = aws_vpc.project1-vpc.id
  cidr_block              = "10.0.16.0/20"
  map_public_ip_on_launch = "true"
  availability_zone       = "eu-west-2b"

  tags = {
    Name = "project-public-2"
  }
}

# Creating Internet Gateway in AWS VPC
resource "aws_internet_gateway" "project1-vpc-gw" {
  vpc_id = aws_vpc.project1-vpc.id

  tags = {
    Name = "project1-vpc"
  }
}

# Creating Route Tables for Internet gateway
resource "aws_route_table" "project1-vpc-public" {
  vpc_id = aws_vpc.project1-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project1-vpc-gw.id
  }

  tags = {
    Name = "project-public-1"
  }
}

# Creating Route Associations public subnets
resource "aws_route_table_association" "project1-vpc-public-1-a" {
  subnet_id      = aws_subnet.project1-vpc-public-1.id
  route_table_id = aws_route_table.project1-vpc-public.id
}

resource "aws_route_table_association" "dev-public-2-a" {
  subnet_id      = aws_subnet.dev-public-2.id
  route_table_id = aws_route_table.project1-vpc-public
}


# Creating EC2 instances in public subnets
resource "aws_instance" "public_inst_1" {
  ami           = "ami-0c1a7f89451184c8b"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.project-public-1.id}"
  key_name = "key11"
  tags = {
    Name = "public_inst_1"
  }
}

resource "aws_instance" "public_inst_2" {
  ami           = "ami-0c1a7f89451184c8b"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.project-public-2.id}"
  key_name = "key11"
  tags = {
    Name = "public_inst_2"
  }
}