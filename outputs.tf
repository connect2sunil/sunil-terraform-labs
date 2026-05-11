output "vpc_id" {
  description = "ID of VPC A"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the 2 public subnets"
  value       = aws_subnet.public[*].id # [*] = splat — returns all values as a list
}

output "private_subnet_ids" {
  description = "IDs of the 2 private subnets"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  description = "IDs of both NAT Gateways"
  value       = [aws_nat_gateway.az_a.id, aws_nat_gateway.az_b.id]
}

output "sg_web_alb_id" {
  description = "ID of the web/ALB security group"
  value       = aws_security_group.web_alb.id
}

output "sg_app_id" {
  description = "ID of the app tier security group"
  value       = aws_security_group.app.id
}

output "sg_db_id" {
  description = "ID of the db tier security group"
  value       = aws_security_group.db.id
}