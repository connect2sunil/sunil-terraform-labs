resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-a-${var.environment}"   
  }
}
# ═══════════════════════════════════════════════════════════
# SUBNETS — 2 public + 2 private across 2 AZs
# ═══════════════════════════════════════════════════════════

resource "aws_subnet" "public" {
  count = 2

  vpc_id            = aws_vpc.main.id                        
  cidr_block        = var.public_subnet_cidrs[count.index]    
  availability_zone = var.availability_zones[count.index]     

  # EC2s launched in public subnets get a public IP automatically
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index + 1}-${var.environment}"
    Tier = "Public"
  }
}

resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  # Private subnets — no public IPs ever
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-${count.index + 1}-${var.environment}"
    Tier = "Private"
  }
}

# ═══════════════════════════════════════════════════════════
# ROUTE TABLES — one public, two private (per AZ)
# ═══════════════════════════════════════════════════════════

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "rt-public-${var.environment}" }
}

resource "aws_route_table" "private_az_a" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "rt-private-az-a-${var.environment}" }
}

resource "aws_route_table" "private_az_b" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "rt-private-az-b-${var.environment}" }
}


resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_az_a" {
  subnet_id      = aws_subnet.private[0].id
  route_table_id = aws_route_table.private_az_a.id
}

resource "aws_route_table_association" "private_az_b" {
  subnet_id      = aws_subnet.private[1].id
  route_table_id = aws_route_table.private_az_b.id
}