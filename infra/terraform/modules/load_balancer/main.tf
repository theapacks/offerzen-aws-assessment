locals {
  name_prefix = "${var.project_name}-${var.environment}"
  alb_names = {
    for name, _ in var.load_balancers :
    name => trimsuffix(substr("${local.name_prefix}-${name}-alb", 0, 32), "-")
  }
  target_group_names = {
    for name, _ in var.load_balancers :
    name => trimsuffix(substr("${local.name_prefix}-${name}-tg", 0, 32), "-")
  }
}

#      _    _     ____      
#     / \  | |   | __ ) ___ 
#    / _ \ | |   |  _ \/ __|
#   / ___ \| |___| |_) \__ \
#  /_/   \_\_____|____/|___/

resource "aws_lb" "this" {
  for_each = var.load_balancers

  name               = local.alb_names[each.key]
  internal           = each.value.internal
  load_balancer_type = "application"
  security_groups    = [var.security_group_ids[each.key]]
  subnets            = var.subnet_map[each.value.subnet_type]

  enable_deletion_protection = false

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-${each.key}-alb"
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

  name        = local.target_group_names[each.key]
  port        = each.value.target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = each.value.target_type

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
