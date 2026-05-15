# ═══════════════════════════════════════════════════════════
# SECURITY GROUPS
# ═══════════════════════════════════════════════════════════

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

resource "aws_security_group_rule" "web_alb_https_in" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_alb.id
  description       = "Allow HTTPS inbound from internet"
}

resource "aws_security_group_rule" "web_alb_http_out" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
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
  protocol          = "-1"
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

# ═══════════════════════════════════════════════════════════
# NETWORK ACLs — stateless subnet-level firewall
# Explicit associations — avoids stale association ID errors
# ═══════════════════════════════════════════════════════════

resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "nacl-public-${var.environment}" }
}

resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "nacl-private-${var.environment}" }
}

resource "aws_network_acl_association" "public" {
  count          = 2
  network_acl_id = aws_network_acl.public.id
  subnet_id      = aws_subnet.public[count.index].id
}

resource "aws_network_acl_association" "private" {
  count          = 2
  network_acl_id = aws_network_acl.private.id
  subnet_id      = aws_subnet.private[count.index].id
}

# ── PUBLIC NACL RULES ──────────────────────────────────────

resource "aws_network_acl_rule" "public_inbound_http" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "public_inbound_https" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "public_inbound_ephemeral" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 120
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "public_outbound_all" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

# ── PRIVATE NACL RULES ─────────────────────────────────────

resource "aws_network_acl_rule" "private_inbound_vpc" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 0
  to_port        = 65535
}

resource "aws_network_acl_rule" "private_inbound_ephemeral" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "private_outbound_all" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

resource "aws_security_group_rule" "web_alb_ssh_in" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_alb.id
  description       = "Temporary SSH - remove after flow logs testing"
}
resource "aws_network_acl_rule" "public_inbound_ssh" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 130
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}