locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

#      _    _     ____      
#     / \  | |   | __ ) ___ 
#    / _ \ | |   |  _ \/ __|
#   / ___ \| |___| |_) \__ \
#  /_/   \_\_____|____/|___/

resource "aws_lb" "this" {
  for_each = var.load_balancers

  name               = "${local.name_prefix}-${each.key}-alb"
  internal           = each.value.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[each.key].id]
  subnets            = var.subnet_map[each.value.subnet_type]

  enable_deletion_protection = false

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-${each.key}-alb"
  })
}

#      _    _     ____    ____                       _ _            ____                       
#     / \  | |   | __ )  / ___|  ___  ___ _   _ _ __(_) |_ _   _   / ___|_ __ ___  _   _ _ __  
#    / _ \ | |   |  _ \  \___ \ / _ \/ __| | | | '__| | __| | | | | |  _| '__/ _ \| | | | '_ \ 
#   / ___ \| |___| |_) |  ___) |  __/ (__| |_| | |  | | |_| |_| | | |_| | | | (_) | |_| | |_) |
#  /_/   \_\_____|____/  |____/ \___|\___|\__,_|_|  |_|\__|\__, |  \____|_|  \___/ \__,_| .__/ 
#                                                          |___/                        |_|    
resource "aws_security_group" "alb" {
  for_each = var.load_balancers

  name        = "${local.name_prefix}-${each.key}-alb-sg"
  description = "Security group for ${each.key} ALB"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = [
      each.value.enable_http ? { port = each.value.listener_port, protocol = "HTTP" } : null,
      each.value.enable_https ? { port = 443, protocol = "HTTPS" } : null
    ]
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = each.value.allowed_cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-${each.key}-alb-sg"
  })
}

#   _____                    _      ____                           
#  |_   _|_ _ _ __ __ _  ___| |_   / ___|_ __ ___  _   _ _ __  ___ 
#    | |/ _` | '__/ _` |/ _ \ __| | |  _| '__/ _ \| | | | '_ \/ __|
#    | | (_| | | | (_| |  __/ |_  | |_| | | | (_) | |_| | |_) \__ \
#    |_|\__,_|_|  \__, |\___|\__|  \____|_|  \___/ \__,_| .__/|___/
#                 |___/                                 |_|        
resource "aws_lb_target_group" "this" {
  for_each = var.load_balancers

  name        = "${local.name_prefix}-${each.key}-tg"
  port        = each.value.target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    healthy_threshold   = each.value.health_check_healthy_threshold
    unhealthy_threshold = each.value.health_check_unhealthy_threshold
    timeout             = each.value.health_check_timeout
    interval            = each.value.health_check_interval
    path                = each.value.health_check_path
    matcher             = "200"
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-${each.key}-tg"
  })
}

#  _   _ _____ _____ ____    _     _     _                           
# | | | |_   _|_   _|  _ \  | |   (_)___| |_ ___ _ __   ___ _ __ ___ 
# | |_| | | |   | | | |_) | | |   | / __| __/ _ \ '_ \ / _ \ '__/ __|
# |  _  | | |   | | |  __/  | |___| \__ \ ||  __/ | | |  __/ |  \__ \
# |_| |_| |_|   |_| |_|     |_____|_|___/\__\___|_| |_|\___|_|  |___/

resource "aws_lb_listener" "http" {
  for_each = {
    for name, config in var.load_balancers : name => config if config.enable_http
  }

  load_balancer_arn = aws_lb.this[each.key].arn
  port              = each.value.listener_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }
}

#  _   _ _____ _____ ____  ____    _     _     _                           
# | | | |_   _|_   _|  _ \/ ___|  | |   (_)___| |_ ___ _ __   ___ _ __ ___ 
# | |_| | | |   | | | |_) \___ \  | |   | / __| __/ _ \ '_ \ / _ \ '__/ __|
# |  _  | | |   | | |  __/ ___) | | |___| \__ \ ||  __/ | | |  __/ |  \__ \
# |_| |_| |_|   |_| |_|   |____/  |_____|_|___/\__\___|_| |_|\___|_|  |___/

resource "aws_lb_listener" "https" {
  for_each = {
    for name, config in var.load_balancers : name => config if config.enable_https
  }

  load_balancer_arn = aws_lb.this[each.key].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = each.value.ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }
}
