# ═══════════════════════════════════════════════════════════
# TEST EC2 — temporary, for generating VPC flow log traffic
# Delete this file after flow logs verified
# ═══════════════════════════════════════════════════════════

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "test" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.web_alb.id]
  associate_public_ip_address = true
  key_name                    = "SydneyKey"

  tags = { Name = "test-flow-logs-${var.environment}" }
}
output "test_ec2_public_ip" {
  value = aws_instance.test.public_ip
}



resource "aws_security_group" "test_ec2" {
  name        = "test-ec2-sg-${var.environment}"
  description = "Temporary SG for test EC2 - allow SSH"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "test-ec2-sg-${var.environment}" }
}

resource "aws_security_group_rule" "test_ec2_ssh_in" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.test_ec2.id
  description       = "Allow SSH inbound - temp test only"
}

resource "aws_security_group_rule" "test_ec2_all_out" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.test_ec2.id
  description       = "Allow all outbound"
}


