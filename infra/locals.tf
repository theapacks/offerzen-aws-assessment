locals {
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      service     = "rewards"
      owner       = "candidate"
      cost_center = "payments"
    },
    var.additional_tags
  )
}
