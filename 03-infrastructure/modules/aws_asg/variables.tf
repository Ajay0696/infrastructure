variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "role" {
  description = "Role of nodes in this ASG: controlplane or worker"
  type        = string
  validation {
    condition     = contains(["controlplane", "worker"], var.role)
    error_message = "role must be controlplane or worker."
  }
}

variable "ami_id" {
  description = "AMI ID for instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3a.medium"
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Private subnet IDs where instances will be launched"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs to attach to instances"
  type        = list(string)
}

variable "iam_instance_profile_name" {
  description = "IAM instance profile name"
  type        = string
}

variable "desired_capacity" {
  description = "Desired number of instances in the ASG"
  type        = number
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
}

variable "user_data" {
  description = "Base64-encoded user data script"
  type        = string
  default     = ""
}

variable "target_group_arns" {
  description = "List of NLB target group ARNs to register with"
  type        = list(string)
  default     = []
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 50
}

variable "spot_max_price" {
  description = "Maximum spot price per hour. Empty string = on-demand price cap."
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "Cluster name tag value (used by cluster-autoscaler)"
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
