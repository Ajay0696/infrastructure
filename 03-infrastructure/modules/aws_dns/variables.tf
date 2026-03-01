variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 Hosted Zone ID"
  type        = string
}

variable "api_server_dns_name" {
  description = "DNS name to create for the API server (e.g. api.mgmt.ajayshandbook.internal)"
  type        = string
}

variable "nlb_dns_name" {
  description = "DNS name of the target NLB"
  type        = string
}

variable "nlb_zone_id" {
  description = "Hosted zone ID of the target NLB"
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
