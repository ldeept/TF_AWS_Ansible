# Create VPC in us-east-1

resource "aws_vpc" "vpc_master" {
  provider             = aws.region-master
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "master-vpc-splunk"
  }
}

# Create VPC in us-west-2

resource "aws_vpc" "vpc_slave" {
  provider             = aws.region-slave
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "slave-vpc-splunk"
  }
}


# Create IGW in us-east-1
resource "aws_internet_gateway" "igw_master" {
  provider = aws.region-master
  vpc_id   = aws_vpc.vpc_master.id
}

# Create IGW in us-west-2
resource "aws_internet_gateway" "igw_slave" {
  provider = aws.region-slave
  vpc_id   = aws_vpc.vpc_slave.id
}

# Get all available AZ's in vpc for master region
data "aws_availability_zones" "azs" {
  provider = aws.region-master
  state    = "available"
}

# Create Subnet 1 in us-east-1
resource "aws_subnet" "subnet_1_master" {
  provider          = aws.region-master
  availability_zone = element(data.aws_availability_zones.azs.names, 0)
  vpc_id            = aws_vpc.vpc_master.id
  cidr_block        = "10.0.1.0/24"
  tags = {
    Name = "master-splunk-subnet-1"
  }
}

# Create Subnet 2 in us-east-1
resource "aws_subnet" "subnet_2_master" {
  provider          = aws.region-master
  availability_zone = element(data.aws_availability_zones.azs.names, 1)
  vpc_id            = aws_vpc.vpc_master.id
  cidr_block        = "10.0.2.0/24"
  tags = {
    Name = "master-splunk-subnet-2"
  }
}

# Create Subnet 1 in us-west-2
resource "aws_subnet" "subnet_1_slave" {
  provider   = aws.region-slave
  vpc_id     = aws_vpc.vpc_slave.id
  cidr_block = "192.168.1.0/24"
  tags = {
    Name = "slave-splunk-subnet-1"
  }
}

# Initiate VPC Peering connection request from us-east-1
resource "aws_vpc_peering_connection" "us-east-1-us-west-2" {
  provider    = aws.region-master
  peer_vpc_id = aws_vpc.vpc_slave.id
  vpc_id      = aws_vpc.vpc_master.id
  peer_region = var.region-slave
}

# Accept vPC Peering request in us-west-2 from us-east-1
resource "aws_vpc_peering_connection_accepter" "accept_peering" {
  provider                  = aws.region-slave
  vpc_peering_connection_id = aws_vpc_peering_connection.us-east-1-us-west-2.id
  auto_accept               = true
}

# Create route table in us-east-1
resource "aws_route_table" "internet_route" {
  provider = aws.region-master
  vpc_id   = aws_vpc.vpc_master.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_master.id
  }
  route {
    cidr_block                = "192.168.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.us-east-1-us-west-2.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "Master-Region-RT"
  }
}

#Overwrite default route table of VPC(Master) with out route table entries
resource "aws_main_route_table_association" "set-master-default-rt-assoc" {
  provider       = aws.region-master
  vpc_id         = aws_vpc.vpc_master.id
  route_table_id = aws_route_table.internet_route.id
}

# Create route table in us-west-2
resource "aws_route_table" "internet_route_west" {
  provider = aws.region-slave
  vpc_id   = aws_vpc.vpc_slave.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_slave.id
  }
  route {
    cidr_block                = "10.0.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.us-east-1-us-west-2.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "Slave-Region-RT"
  }
}

#Overwrite default route table of VPC(Slave) with out route table entries
resource "aws_main_route_table_association" "set-slave-default-rt-assoc" {
  provider       = aws.region-slave
  vpc_id         = aws_vpc.vpc_slave.id
  route_table_id = aws_route_table.internet_route_west.id
}
