variable "common_tags" {
  description = "Common Tags"
  type        = map(string)
  default     = {
    terraform_managed    = "true"
    owning_team  = "EmergingTechServices"
  }
}

variable "vpc_name" {
  description = "Name of VPC"
  type  = string
}

variable "cidr_block" {
  description = "VPC CIDR"
  type = string
}

# variable "az" {
#   description = "Availability Zones"
#   type = list(string)
# }

# variable "public_subnets" {
#   description = "List of public subnet CIDRs"
#   type = list(string)
# }

# variable "private_subnets" {
#   description = "List of private subnet CIDRs"
#   type = list(string)
# }

variable "availability_zones" {
  type = map(string)
  description = "AZs mapped to subnet keys"
}

variable "public_subnets" {
  description = "Map of public subnet CIDR blocks with keys for identification"
  type = map(string)
}

variable "private_subnets" {
  description = "Map of private subnet CIDR blocks with keys for identification"
  type = map(string)
}


variable "enable_private_subnets" {
  type        = bool
  description = "Toggle for private subnet/NAT infra"
  default     = false
}
