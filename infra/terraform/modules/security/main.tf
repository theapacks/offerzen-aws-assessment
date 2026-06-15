locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_security_group" "ui_alb" {
  name        = "${local.name_prefix}-ui-alb-sg"
  description = "Public UI ALB security group"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ui_listener_ports
    content {
      description = "Allow inbound traffic to UI ALB listener"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = var.ui_alb_allowed_cidr_blocks
    }
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-ui-alb-sg"
    Tier = "public"
  })
}

resource "aws_security_group" "backend_alb" {
  name        = "${local.name_prefix}-backend-alb-sg"
  description = "Internal backend ALB security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow UI ALB to reach backend ALB"
    from_port       = var.backend_listener_port
    to_port         = var.backend_listener_port
    protocol        = "tcp"
    security_groups = [aws_security_group.ui_alb.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-backend-alb-sg"
    Tier = "private"
  })
}

resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-app-sg"
  description = "Application compute tier security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow backend ALB to reach compute instances"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_alb.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-app-sg"
    Tier = "private"
  })
}

resource "aws_security_group" "ui_instance" {
  name        = "${local.name_prefix}-ui-instance-sg"
  description = "UI compute tier security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow UI ALB to reach UI compute instances"
    from_port       = try(var.ui_listener_ports[0], 80) # Assuming the first port is the one for instances
    to_port         = try(var.ui_listener_ports[0], 80)
    protocol        = "tcp"
    security_groups = [aws_security_group.ui_alb.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-ui-instance-sg"
    Tier = "public"
  })
}

