variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnets" {
  description = "Map of public subnet names to CIDR blocks"
  type        = map(string)
}

variable "private_subnets" {
  description = "Map of private subnet names to CIDR blocks"
  type        = map(string)
}

variable "azs" {
  description = "List of Availability Zones"
  type        = list(string)
}

variable "tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default     = {}
}


