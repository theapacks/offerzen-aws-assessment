locals {
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Service     = "rewards"
      CostCenter  = "payments"
    },
    var.additional_tags
  )
}
