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
  description                     = "Main TGW - connects VPC A and VPC B"
  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  tags = {
    Name = "tgw-${var.environment}"
  }

}

resource "aws_ec2_transit_gateway_vpc_attachment" "vpc_a" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.main.id
  # Subnets where TGW creates ENIs — one per AZ for resilience
  # Use private subnets — TGW ENIs should not be in public subnets
  subnet_ids = [
    aws_subnet.private[0].id,
    aws_subnet.private[1].id,
  ]
  tags = {
    Name = "tgw-attachment-vpc-a-${var.environment}"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "vpc_b" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = aws_vpc.vpc_b.id
  subnet_ids = [
    aws_subnet.vpc_b_private[0].id,
    aws_subnet.vpc_b_private[1].id,
  ]

  tags = {
    Name = "tgw-attachment-vpc-b-${var.environment}"
  }
}

# ═══════════════════════════════════════════════════════════
# ROUTES — tell each VPC how to reach the other via TGW
# ═══════════════════════════════════════════════════════════

# Route in VPC A private route tables — to reach VPC B, use TGW
resource "aws_route" "vpc_a_to_vpc_b_az_a" {
  route_table_id         = aws_route_table.private_az_a.id
  destination_cidr_block = var.vpc_b_cidr # 10.1.0.0/16
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.vpc_a]

}

resource "aws_route" "vpc_a_to_vpc_b_az_b" {
  route_table_id         = aws_route_table.private_az_b.id
  destination_cidr_block = var.vpc_b_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.vpc_a]
}

# Route in VPC B route table — to reach VPC A, use TGW
resource "aws_route" "vpc_b_to_vpc_a" {
  route_table_id         = aws_route_table.vpc_b_private.id
  destination_cidr_block = var.vpc_cidr # 10.0.0.0/16 — VPC A CIDR
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.vpc_b]
}