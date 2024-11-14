# VPC
data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_subnet" "vpc_subnets" {
  for_each = toset(var.vpc_subnet_ids)
  id       = each.value
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
}

data "aws_security_group" "inbound" {
  count = length(var.security_groups)
  id    = var.security_groups[count.index]
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
}
