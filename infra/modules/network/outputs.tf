output "vpc_id" {
  description = "ID of the created VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the created VPC."
  value       = aws_vpc.this.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway when created."
  value       = try(aws_internet_gateway.this[0].id, null)
}

output "public_subnet_ids" {
  description = "IDs of created public subnets."
  value       = values(aws_subnet.public)[*].id
}

