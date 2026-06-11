output "load_balancers" {
  description = "Map of load balancer details keyed by name."
  value = {
    for name, alb in aws_lb.this : name => {
      arn               = alb.arn
      dns_name          = alb.dns_name
      security_group_id = aws_security_group.alb[name].id
      target_group_arn  = aws_lb_target_group.this[name].arn
      internal          = alb.internal
    }
  }
}

output "load_balancer_target_groups" {
  description = "Map of target group ARNs keyed by ALB name."
  value = {
    for name, tg in aws_lb_target_group.this : name => tg.arn
  }
}

