resource "aws_security_group" "web_alb" {
  name        = "web-alb-${var.environment}"
  description = "ALB/web tier - accepts HTTP and HTTPS from internet"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "web-sg-alb-${var.environment}" }
}

resource "aws_security_group_rule" "web_alb_http_in" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_alb.id
  description       = "Allow HTTP inbound from internet"
}

resource "aws_security_group_rule" "web_alb_http_out" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_alb.id
  description       = "Allow all outbound"
}

resource "aws_security_group" "app" {
  name        = "app-${var.environment}"
  description = "App tier - accepts traffic from web SG only"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "app-sg-${var.environment}" }
}

resource "aws_security_group_rule" "app_from_web" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web_alb.id
  security_group_id        = aws_security_group.app.id
  description              = "Allow port 8080 from web ALB SG only"
}

resource "aws_security_group_rule" "app_all_out" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app.id
  description       = "Allow all outbound"
}

resource "aws_security_group" "db" {
  name        = "db-${var.environment}"
  description = "DB Tier - accepts MySQL 3306 from app SG only"
  vpc_id      = aws_vpc.main.id
  tags        = { Name = "db-sg-${var.environment}" }
}

resource "aws_security_group_rule" "db_from_app" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.db.id
  description              = "Allow MySQL 3306 from app SG only"
}

resource "aws_security_group_rule" "db_all_out" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.db.id
  description       = "Allow all outbound"
}