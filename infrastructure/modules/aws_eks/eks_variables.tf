variable "region" {
  type        = string
  description = "AWS region"
}

variable "cluster_name" {
  type        = string
  description = "EKS Cluster name"
}

variable "k8s_version" {
  type        = string
  default     = "1.34"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "All subnet IDs"
}

variable "public_subnets" {
  type        = list(string)
  description = "Public subnet IDs"
}

variable "private_subnets" {
  type        = list(string)
  description = "Private subnet IDs"
}

variable "tags" {
  type        = map(string)
  default     = {}
}

# -----------------------------
# Node group configuration
# -----------------------------

variable "node_instance_type" {
  description = "Instance type for worker nodes"
  type        = string
  default     = "t3a.medium"
}

variable "node_desired_size" {
  description = "Desired number of nodes in the node group"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of nodes in the node group"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of nodes in the node group"
  type        = number
  default     = 3
}

variable "spot_enabled" {
  description = "Whether to use Spot Instances for worker nodes"
  type        = bool
  default     = false
}

variable "node_groups" {
  description = "Map of EKS node groups (internal, external, etc.) with configuration"
  type = map(object({
    instance_type = string
    min_size      = number
    max_size      = number
    desired_size  = number
    spot_enabled  = bool
    subnet_type   = string # 'public' or 'private'
  }))
}