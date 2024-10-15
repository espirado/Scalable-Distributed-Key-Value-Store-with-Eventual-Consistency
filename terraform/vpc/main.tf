resource "aws_vpc" "key_store" {
    cidr_block = var.vpc_cidr
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "scalable-distributed-kv-store-vpc"
    }
}

resource "aws_subnet" "public" {
    count = length(var.availability_zones)
    vpc_id = aws_vpc.key_store.id
    cidr_block = var.public_subnet_cidrs[count.index]
    availability_zone = element(var.availability_zones, count.index)
    map_public_ip_on_launch = true
    tags = {
        Name = "terraform-public-subnet-${count.index}"
    }
}

resource "aws_subnet" "private" {
    count = length(var.availability_zones)
    vpc_id = aws_vpc.key_store.id
    cidr_block = var.private_subnet_cidrs[count.index]
    availability_zone = element(var.availability_zones, count.index)
    tags = {
        Name = "terraform-private-subnet-${count.index}"
    }
}

resource "aws_internet_gateway" "key_store" {
    vpc_id = aws_vpc.key_store.id
    tags = {
        Name = "scalable-kv-store-igw"
    }
}

resource "aws_route_table" "key_store" {
    vpc_id = aws_vpc.key_store.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.key_store.id
    }

    tags = {
        Name = "public-route-table"
    }
}

resource "aws_eip" "nat" {
    domain = "vpc"  
    tags = {
        Name = "nat-eip"
    }
}

resource "aws_nat_gateway" "key_store" {
    allocation_id = aws_eip.nat.id
    subnet_id = aws_subnet.public[0].id  # Fix this reference
    tags = {
        Name = "scalable-kv-store-nat"
    }
}
