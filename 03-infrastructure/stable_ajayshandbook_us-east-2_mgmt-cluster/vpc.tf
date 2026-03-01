module "vpc" {
  source = "../modules/aws_vpc"

  name_prefix         = local.name_prefix
  vpc_cidr            = local.vpc_cidr
  availability_zones  = local.availability_zones
  public_subnet_cidrs = local.public_subnet_cidrs

  tags = local.common_tags
}
