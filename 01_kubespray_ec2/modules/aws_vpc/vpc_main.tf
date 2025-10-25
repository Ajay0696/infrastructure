#VPC Creation

resource "aws_vpc" "main" {
  cidr_block       = var.cidr_block

  enable_dns_hostnames = true
  enable_dns_support = true

  tags = merge(
    var.common_tags,
    {
      Name = var.vpc_name
    }
  )
}

#IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.vpc_name}-igw"
    }
  )
}

# #public subnet with count
# resource "aws_subnet" "public" {
#   count = length(var.public_subnets)
#   vpc_id     = aws_vpc.main.id
#   cidr_block = var.public_subnets[count.index]
#   availability_zone = var.az[count.index]

#   tags = merge(
#     var.common_tags,
#     {
#       Name = "${var.vpc_name}-public-${count.index + 1}"
#     }
#   )
# }

# #Private subnet with count
# resource "aws_subnet" "private" {
#   count = length(var.private_subnets)
#   vpc_id     = aws_vpc.main.id
#   cidr_block = var.private_subnets[count.index]
#   availability_zone = var.az[count.index]

#   tags = merge(
#     var.common_tags,
#     {
#       Name = "${var.vpc_name}-private-${count.index + 1}"
#     }
#   )
# }

# Public Subnet with for_each
resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = var.availability_zones[each.key]
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    {
      "Name" = "${var.vpc_name}-${each.key}-public"
      "subnettype" = "public"
      "kubernetes.io/role/elb"                      = "1"

    }
  )
}

# Private Subnet with for_each
resource "aws_subnet" "private" {
  for_each = var.enable_private_subnets ? var.private_subnets : {}

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = var.availability_zones[each.key]

  tags = merge(
    var.common_tags,
    {
      "Name" = "${var.vpc_name}-${each.key}-private"
      "subnettype" = "private"
    }
  )
}

#EIP
resource "aws_eip" "nat" {
  count = var.enable_private_subnets ? 1 : 0
  domain = "vpc"

  tags = merge(var.common_tags, {
    Name = "${var.vpc_name}-eip"
  })
}

#NAT gw
resource "aws_nat_gateway" "nat" {
  count         = var.enable_private_subnets ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = values(aws_subnet.public)[0].id
  depends_on    = [aws_internet_gateway.igw]

  tags = merge(var.common_tags, {
    Name = "${var.vpc_name}-nat"
  })
}

#public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.vpc_name}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = var.enable_private_subnets ? 1 : 0
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[0].id
  }

  tags = merge(var.common_tags, {
    Name = "${var.vpc_name}-private-rt"
  })
}

resource "aws_route_table_association" "private" {
  for_each = var.enable_private_subnets ? aws_subnet.private : {}

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[0].id
}

