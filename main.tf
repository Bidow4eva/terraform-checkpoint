provider "aws" {
  region     = "us-east-1"  
  access_key = "AKIASQIGBXH6F5N4LPF4"  
  secret_key = "Oh0zVBD6kgGi0kEHStLCa5QS4yUEzFfC2+i7m5ap"  # Replace with your AWS secret key
}

// Define VPC
resource "aws_vpc" "vpc" {
    cidr_block = var.VpcCIDR
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
    Name = "${var.EnvironmentName}-VPC"
    }
}

// internet gate
resource "aws_internet_gateway" "internet_gateway" {
    vpc_id = aws_vpc.vpc.d
    tags = {
        Name = "${var.EnvironmentName}-InternetGateway"
    }
}
// Internet gateway to vpc
resource "aws_vpc_attatchment" "internet_gateway" {
    vpc_id = aws_vpc.vpc.id
    internet_gateway_id = aws_internet_gateway.internet_gateway.id
}

// public subenet in first avalability zone
resource "aws_subnet" "public_subnet_1" {
    vpc_id = aws_vpc.vpc.d
    availability_zone = elment(data.aws_availabily_zones.available.names, 0)
    cidr_block = var.PublicSubnet1CIDR
    map_public_ip_on_launch = true
    tags = {
        Name = "${var.EnvironmentName}-Public-Web-Subnet-(AZ1)"
    }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = element(data.aws_availability_zones.available.names, 1)
  cidr_block              = var.public_subnet_2_cidr
  map_public_ip_on_launch = true
  tags = {
    Name = format("%s-Public-Web-Subnet-(AZ2)", var.environment_name)
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = element(data.aws_availability_zones.available.names, 0)
  cidr_block              = var.private_subnet_1_cidr
  map_public_ip_on_launch = false
  tags = {
    Name = format("%s-Private-App-Subnet-(AZ1)", var.environment_name)
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = element(data.aws_availability_zones.available.names, 1)
  cidr_block              = var.private_subnet_1_cidr
  map_public_ip_on_launch = false
  tags = {
    Name = format("%s-Private-App-Subnet-(AZ2)", var.environment_name)
  }
}

resource "aws_subnet" "private_subnet_3" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = element(data.aws_availability_zones.available.names, 0)
  cidr_block              = var.private_subnet_1_cidr
  map_public_ip_on_launch = false
  tags = {
    Name = format("%s-Private-App-Subnet-(AZ1)", var.environment_name)
  }
}

resource "aws_subnet" "private_subnet_4" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = element(data.aws_availability_zones.available.names, 1)
  cidr_block              = var.private_subnet_1_cidr
  map_public_ip_on_launch = false
  tags = {
    Name = format("%s-Private-App-Subnet-(AZ2)", var.environment_name)
  }
}

resource "aws_eip" "nat_eip" {
  domain = "vps"
  tags = {
    Name =format ("%s-ElasticIP, var.environment_name")
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  depends_on  = [aws_subnet.public_subnet_1]
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id
  tags = {
    Name = format("%s-NatGateway", var.environment_name)
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = format("%s-PublicRouteTable", var.environment_name)
  }
}

resource "aws_route" "default_public_route" {
  route_table_id            = aws_route_table.public_route_table.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.internet_gateway.id
}

resource "aws_route_table_association" "public_subnet1_association" {
  subnet_id      = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet2_association" {
  subnet_id      = aws_subnet.public_subnet2.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.environment_name}-PrivateRouteTable"
  }
}

resource "aws_route" "default_private_route" {
  route_table_id            = aws_route_table.private_route_table.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id            = aws_nat_gateway.nat_gateway.id
}

resource "aws_route_table_association" "private_subnet1_association" {
  subnet_id      = aws_subnet.private_subnet1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet2_association" {
  subnet_id      = aws_subnet.private_subnet2.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet3_association" {
  subnet_id      = aws_subnet.private_subnet3.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet4_association" {
  subnet_id      = aws_subnet.private_subnet4.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_security_group" "bastion_host_security_group" {
  name        = "${var.environment_name}-BastionHost-SecurityGroup"
  description = "Security group for Bastion Host"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_security_group_rule" "bastion_host_security_group_rule" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion_host_security_group.id
}

resource "aws_security_group" "web_tier_lb_security_group" {
  name        = "${var.environment_name}-WebTierLB-SecurityGroup"
  description = "Security group for Web Tier Load Balancer"
  vpc_id      = aws_vpc.vpc.id
}