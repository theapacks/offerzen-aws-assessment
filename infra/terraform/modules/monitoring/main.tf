locals {
  name_prefix = "${var.project_name}-${var.environment}"
  tiers = {
    ui = {
      alb_arn_suffix          = var.ui_alb_arn_suffix
      target_group_arn_suffix = var.ui_target_group_arn_suffix
      asg_name                = var.ui_asg_name
      desired_capacity        = var.ui_desired_capacity
    }
    backend = {
      alb_arn_suffix          = var.backend_alb_arn_suffix
      target_group_arn_suffix = var.backend_target_group_arn_suffix
      asg_name                = var.backend_asg_name
      desired_capacity        = var.backend_desired_capacity
    }
  }
}

resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-alerts"
  })
}

resource "aws_sns_topic_subscription" "email" {
  count = var.alarm_email_endpoint == null ? 0 : 1

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email_endpoint
}

resource "aws_cloudwatch_metric_alarm" "alb_target_5xx" {
  for_each = local.tiers

  alarm_name          = "${local.name_prefix}-${each.key}-alb-target-5xx"
  alarm_description   = "ALB target 5XX count is above threshold for ${each.key}."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  statistic           = "Sum"
  period              = var.period_seconds
  evaluation_periods  = var.evaluation_periods
  threshold           = var.alb_5xx_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = each.value.alb_arn_suffix
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "alb_target_response_time" {
  for_each = local.tiers

  alarm_name          = "${local.name_prefix}-${each.key}-alb-target-response-time"
  alarm_description   = "ALB target response time is above threshold for ${each.key}."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  statistic           = "Average"
  period              = var.period_seconds
  evaluation_periods  = var.evaluation_periods
  threshold           = var.alb_target_response_time_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = each.value.alb_arn_suffix
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "target_unhealthy_hosts" {
  for_each = local.tiers

  alarm_name          = "${local.name_prefix}-${each.key}-target-unhealthy-hosts"
  alarm_description   = "ALB target group unhealthy host count is above threshold for ${each.key}."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Maximum"
  period              = var.period_seconds
  evaluation_periods  = var.evaluation_periods
  threshold           = var.unhealthy_host_count_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = each.value.alb_arn_suffix
    TargetGroup  = each.value.target_group_arn_suffix
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "asg_in_service_instances" {
  for_each = local.tiers

  alarm_name          = "${local.name_prefix}-${each.key}-asg-in-service-low"
  alarm_description   = "ASG in-service instance count dropped below desired capacity for ${each.key}."
  namespace           = "AWS/AutoScaling"
  metric_name         = "GroupInServiceInstances"
  statistic           = "Average"
  period              = var.period_seconds
  evaluation_periods  = var.evaluation_periods
  threshold           = each.value.desired_capacity
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = each.value.asg_name
  }

  tags = var.tags
}
