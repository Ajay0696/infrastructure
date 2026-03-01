output "api_server_fqdn" {
  description = "Fully qualified domain name of the Kubernetes API server"
  value       = aws_route53_record.k8s_api.fqdn
}
