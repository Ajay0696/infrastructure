output "nlb_arn" {
  description = "ARN of the NLB"
  value       = aws_lb.k8s_api.arn
}

output "nlb_dns_name" {
  description = "DNS name of the NLB"
  value       = aws_lb.k8s_api.dns_name
}

output "nlb_zone_id" {
  description = "Hosted zone ID of the NLB (for Route53 alias records)"
  value       = aws_lb.k8s_api.zone_id
}

output "target_group_arn" {
  description = "ARN of the API server target group"
  value       = aws_lb_target_group.k8s_api.arn
}
