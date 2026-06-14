resource "aws_launch_template" "app_lt" {
  name_prefix   = "${var.project_name}-${var.environment}-${var.tier_name}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = var.security_group_ids

  update_default_version = true
}

resource "aws_autoscaling_group" "app_asg" {
  name                      = "${var.project_name}-${var.environment}-${var.tier_name}-asg"
  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.subnet_ids
  target_group_arns         = var.target_group_arns
  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-${var.tier_name}-instance"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

