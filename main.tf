provider "aws" {
  region     = "us-west-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

variable "aws_access_key" {
  type        = string
  description = "The AWS access key"
}

variable "aws_secret_key" {
  type        = string
  description = "The AWS secret key"
}



module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = "project-vpc"
  cidr   = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b"]
  public_subnets  = ["10.0.0.0/20", "10.0.16.0/20"]
  private_subnets = ["10.0.128.0/20", "10.0.144.0/20"]

  enable_ipv6        = true
  enable_nat_gateway = false
  single_nat_gateway = true
  public_subnet_tags = {
    Name = "Public-Subnets"
  }
  tags = {
    Owner       = "user"
    Environment = "dev"
  }
  vpc_tags = {
    Name = "project-vpc"
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main"
  }
  enable_dns_support = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
   tags = {
    Name = "main-igw"
  }
}

resource "aws_subnet" "public" {
  count = 2
  cidr_block = "10.0.${count.index+1}.0/24"
  availability_zone = "us-west-2a"
  vpc_id = aws_vpc.main.id
  map_public_ip_on_launch = true
  tags = {
    Name = "public-${count.index+1}"
  }
}

resource "aws_subnet" "private" {
  count = 2
  cidr_block = "10.0.${count.index+3}.0/24"
  availability_zone = "us-west-2a"
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "private-${count.index+1}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public"
  }
}

variable "subnet_cidr_block" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}



resource "aws_security_group" "db" {
  name_prefix = "db"
  description = "Database Security Group"
  vpc_id = aws_vpc.main.id
}
