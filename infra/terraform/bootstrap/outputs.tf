output "state_bucket_name" {
  description = "S3 bucket name for Terraform remote state."
  value       = aws_s3_bucket.terraform_state.bucket
}

output "backend_config_snippet" {
  description = "Suggested backend config values for terraform init -backend-config."
  value = {
    bucket = aws_s3_bucket.terraform_state.bucket
    key    = "${var.environment}/terraform.tfstate"
    region = var.aws_region
  }
}
