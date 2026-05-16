resource "aws_vpc" "vpc_b" {
  cidr_block           = var.vpc_b_cidr # 10.1.0.0/16 — no overlap with VPC A
  enable_dns_hostnames = true           # assigns DNS names to EC2s (e.g. ec2-1-2-3.compute.amazonaws.com)
  enable_dns_support   = true           # enables DNS resolution inside the VPC via Route 53 resolver
  tags = { Name = "vpc-b-${var.environment}"
  }
}

# VPC B has private subnets ONLY — no public subnets, no IGW
# Traffic between VPC A and VPC B flows through Transit Gateway only

resource "aws_subnet" "vpc_b_private" {
  count                   = 2
  vpc_id                  = aws_vpc.vpc_b.id
  cidr_block              = var.vpc_b_private_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false # private — never public IPs

  tags = {
    Name = "vpc-b-private-subnet-${count.index + 1}-${var.environment}"
    Tier = "Private"
    VPC  = "vpc-b"
  }
}

# Route table for VPC B — TGW route will be added in Chunk 2

resource "aws_route_table" "vpc_b_private" {
  vpc_id = aws_vpc.vpc_b.id
  tags   = { Name = "rt-vpc-b-private-${var.environment}" }
}

resource "aws_route_table_association" "vpc_b_private" {
  count          = 2
  subnet_id      = aws_subnet.vpc_b_private[count.index].id
  route_table_id = aws_route_table.vpc_b_private.id
}

# ═══════════════════════════════════════════════════════════
# TRANSIT GATEWAY — the hub
# ═══════════════════════════════════════════════════════════

resource "aws_ec2_transit_gateway" "main" {
  description =  "Main TGW - connects VPC A and VPC B"
  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
tags = {
  Name = "tgw-${var.environment}"
}

}