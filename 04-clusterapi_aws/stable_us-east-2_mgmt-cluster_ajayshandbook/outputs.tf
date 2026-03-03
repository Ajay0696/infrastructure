output "vpc_id" {
  description = "VPC ID used by CAPA"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs used by CAPA"
  value       = [for s in aws_subnet.public : s.id]
}

output "public_subnet_ids_by_az" {
  description = "Public subnet IDs keyed by availability zone"
  value       = { for az, s in aws_subnet.public : az => s.id }
}
