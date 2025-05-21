resource "aws_security_group" "db_sg" {
  name        = "currency-data-sg"
  description = "Allow inbound access to RDS"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr, "10.0.0.0/16"]
    security_groups = [var.security_group]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [var.security_group]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "default" {
  availability_zone = "${var.region}a"
  vpc_id = data.aws_vpc.default.id
}

data "aws_subnet" "defaultb" {
  availability_zone = "${var.region}b"
  vpc_id = data.aws_vpc.default.id
}

data "aws_subnet" "defaultc" {
  availability_zone = "${var.region}c"
  vpc_id = data.aws_vpc.default.id
}

data "aws_route_table" "default_rt" {
  vpc_id = data.aws_vpc.default.id
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id            = data.aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [data.aws_subnet.default.id, data.aws_subnet.defaultb.id, data.aws_subnet.defaultc.id]
  security_group_ids = [aws_security_group.db_sg.id]

  private_dns_enabled = true

  tags = {
    Name = "secretsmanager-endpoint"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = data.aws_vpc.default.id
  service_name = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [data.aws_route_table.default_rt.id]

  tags = {
    Name = "s3-endpoint"
  }
}