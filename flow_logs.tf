# CloudWatch Log Group — where flow log records land

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flow-logs/${var.environment}"
  retention_in_days = 7 # keep 7 days — enough for debugging, limits cost
  tags              = { Name = "vpc-flow-logs-${var.environment}" }
}

resource "aws_iam_role" "vpc_flow_logs" {
  name = "vpc-flow-logs-role-${var.environment}"

  # Trust policy — allows the Flow Logs service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "vpc-flow-logs-role-${var.environment}" }
}

# Permissions policy — what the role can DO once assumed
resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "vpc-flow-logs-policy-${var.environment}"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "*" # in prod scope this to the specific log group ARN
    }]
  })
}

resource "aws_flow_log" "vpc_main" {
  iam_role_arn         = aws_iam_role.vpc_flow_logs.arn
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL" # capture ACCEPT and REJECT records
  vpc_id               = aws_vpc.main.id

  tags = { Name = "flow-log-vpc-main-${var.environment}" }
}

  