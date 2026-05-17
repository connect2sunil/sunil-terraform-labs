# ═══════════════════════════════════════════════════════════
# AMI DATA SOURCE
# Automatically fetches latest Amazon Linux 2023 for ap-southeast-2
# ═══════════════════════════════════════════════════════════

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# ═══════════════════════════════════════════════════════════
# APPLICATION LOAD BALANCER
# Public-facing ALB distributes traffic to private EC2s
# ═══════════════════════════════════════════════════════════

resource "aws_lb" "app" {
  name               = "alb-app-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = { Name = "alb-app-${var.environment}" }
}

# ═══════════════════════════════════════════════════════════
# TARGET GROUP
# ═══════════════════════════════════════════════════════════

resource "aws_lb_target_group" "app" {
  name     = "tg-app-${var.environment}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    matcher             = "200"
  }

  tags = { Name = "tg-app-${var.environment}" }
}

# ═══════════════════════════════════════════════════════════
# LISTENER
# ═══════════════════════════════════════════════════════════

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# ═══════════════════════════════════════════════════════════
# EC2 INSTANCES — app tier targets
# Simple instances running a basic HTTP server for testing
# ═══════════════════════════════════════════════════════════

resource "aws_instance" "app" {
  count         = 2
  ami           = data.aws_ami.al2023.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private[count.index].id

  vpc_security_group_ids = [aws_security_group.app.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y python3
    mkdir -p /var/www/html
    echo "<h1>App server - AZ ${var.availability_zones[count.index]}</h1>" > /var/www/html/index.html
    cd /var/www/html
    nohup python3 -m http.server 80 &
  EOF
  )

  tags = {
    Name = "ec2-app-${count.index + 1}-${var.environment}"
    Tier = "App"
  }
}

# ═══════════════════════════════════════════════════════════
# TARGET GROUP ATTACHMENTS
# ═══════════════════════════════════════════════════════════

resource "aws_lb_target_group_attachment" "app" {
  count            = 2
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app[count.index].id
  port             = 80
}