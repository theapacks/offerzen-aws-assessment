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

output "private_subnet_ids" {
  description = "IDs of created private subnets."
  value       = values(aws_subnet.private)[*].id
}

output "public_route_table_id" {
  description = "ID of the public route table."
  value       = try(aws_route_table.public[0].id, null)
}

output "private_route_table_id" {
  description = "ID of the private route table."
  value       = aws_route_table.private.id
}

output "vpc_endpoints_sg_id" {
  description = "ID of the security group for Interface VPC endpoints."
  value       = try(aws_security_group.vpc_endpoints[0].id, null)
}

output "vpc_endpoint_ids" {
  description = "Map of all VPC endpoint IDs keyed by endpoint name."
  value = merge(
    { for k, v in aws_vpc_endpoint.interface : k => v.id },
    { for k, v in aws_vpc_endpoint.gateway : k => v.id },
  )
}

