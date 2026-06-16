output "sns_topic_arn" {
  description = "ARN of the SNS topic used for alerts."
  value       = aws_sns_topic.alerts.arn
}

output "alarm_names" {
  description = "All CloudWatch alarm names created by this module."
  value = concat(
    [for _, alarm in aws_cloudwatch_metric_alarm.alb_target_5xx : alarm.alarm_name],
    [for _, alarm in aws_cloudwatch_metric_alarm.alb_target_response_time : alarm.alarm_name],
    [for _, alarm in aws_cloudwatch_metric_alarm.target_unhealthy_hosts : alarm.alarm_name],
    [for _, alarm in aws_cloudwatch_metric_alarm.asg_in_service_instances : alarm.alarm_name]
  )
}
