# -------------------------------------------------------
# VPC
# -------------------------------------------------------
resource "aws_vpc" "this" {
  cidr_block           = local.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = local.name_prefix
    # Required so CAPA can discover and use this VPC
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  })
}

# -------------------------------------------------------
# Internet Gateway
# -------------------------------------------------------
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = local.name_prefix
  })
}

# -------------------------------------------------------
# Public Subnets
# -------------------------------------------------------
resource "aws_subnet" "public" {
  for_each = { for s in local.public_subnets : s.az => s }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}_public_${each.key}"
    # Required so CAPA can discover and use these subnets
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  })
}

# -------------------------------------------------------
# Public Route Table
# -------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}_public"
  })
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}
