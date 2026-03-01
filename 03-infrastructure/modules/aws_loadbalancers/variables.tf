variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "lb_name" {
  description = "Name for the NLB (max 32 chars, hyphens only – no underscores)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the NLB"
  type        = list(string)
}

variable "internal" {
  description = "true = internal NLB (access via VPN); false = internet-facing"
  type        = bool
  default     = true
}

variable "api_server_port" {
  description = "Port exposed by the Kubernetes API server"
  type        = number
  default     = 6443
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
