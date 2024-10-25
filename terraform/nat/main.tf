locals {
  name_prefix = "${var.project}-${var.environment}"
  nat_gateway_count = var.create_per_az_nat ? length(var.public_subnet_ids) : 1
}

resource "aws_eip" "nat" {
  count  = local.nat_gateway_count
  domain = "vpc"

  tags = {
    Name        = "${local.name_prefix}-nat-eip-${count.index + 1}"
    Environment = var.environment
    Project     = var.project
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_nat_gateway" "main" {
  count         = local.nat_gateway_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = var.public_subnet_ids[count.index]

  tags = {
    Name        = "${local.name_prefix}-nat-gw-${count.index + 1}"
    Environment = var.environment
    Project     = var.project
  }

  depends_on = [aws_eip.nat]
}

resource "aws_route" "private_nat_gateway" {
  count                  = length(var.private_route_table_ids)
  route_table_id         = var.private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.create_per_az_nat ? aws_nat_gateway.main[count.index].id : aws_nat_gateway.main[0].id
}