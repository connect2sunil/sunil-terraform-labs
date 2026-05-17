variable "aws_region" {
  description = "AWS region to deploy all resources"
  type        = string
  default     = "ap-southeast-2"
}

variable "environment" {
  description = "Environment name — used in resource names and tags"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC A"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for 2 public subnets"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for 2 private subnets"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.3.0/24"]
}

variable "availability_zones" {
  description = "Two AZs in Sydney"
  type        = list(string)
  default     = ["ap-southeast-2a", "ap-southeast-2b"]
}
# ═══════════════════════════════════════════════════════════
# WEEK 3 VARIABLES — VPC B + Transit Gateway
# ═══════════════════════════════════════════════════════════

variable "vpc_b_cidr" {
  description = "CIDR block for VPC B — must not overlap with VPC A (10.0.0.0/16)"
  type        = string
  default     = "10.1.0.0/16"
}

variable "vpc_b_private_subnet_cidrs" {
  description = "CIDR blocks for VPC B private subnets — private only, no IGW"
  type        = list(string)
  default     = ["10.1.0.0/24", "10.1.1.0/24"]
}

variable "domain_name" {
  description = "private hosted zone domain name for Route 53"
  default     = "internal.sunil-labs.com"
}

# EC2 instance type for app tier targets
variable "instance_type" {
  description = "EC2 instance type for app tier"
  type        = string
  default     = "t3.micro"
}

# Amazon Linux 2023 AMI for ap-southeast-2 — update if stale
variable "ami_id" {
  description = "Amazon Linux 2023 AMI ID for ap-southeast-2"
  type        = string
  default     = "ami-0c6c64795de24c2c2"  # AL2023 Sydney — check AWS console for latest
}