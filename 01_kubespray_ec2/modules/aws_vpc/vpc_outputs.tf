output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  value = var.enable_private_subnets ? [for s in aws_subnet.private : s.id] : []
}

output "nat_gateway_id" {
  value = var.enable_private_subnets ? aws_nat_gateway.nat[0].id : null
}