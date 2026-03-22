data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "runs_on" {
  cidr_block           = "10.100.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, { Name = "runs-on-vpc" })
}

resource "aws_internet_gateway" "runs_on" {
  vpc_id = aws_vpc.runs_on.id

  tags = merge(local.common_tags, { Name = "runs-on-igw" })
}

resource "aws_subnet" "public" {
  count = 3

  vpc_id                  = aws_vpc.runs_on.id
  cidr_block              = cidrsubnet(aws_vpc.runs_on.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "runs-on-public-${data.aws_availability_zones.available.names[count.index]}"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.runs_on.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.runs_on.id
  }

  tags = merge(local.common_tags, { Name = "runs-on-public-rt" })
}

resource "aws_route_table_association" "public" {
  count = 3

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
