data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "vpc" {
  count      = var.count_vpc
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.env}"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id                  = "${aws_vpc.vpc.0.id}"
  count                   = "${var.count_vpc == 0 ? 0 : length(split(",", lookup(var.availability_zones, data.aws_region.current.name)))}"
  availability_zone       = "${element(split(",",lookup(var.availability_zones, data.aws_region.current.name)), count.index)}"
  cidr_block              = "10.0.${count.index+length(data.aws_availability_zones.available.names)}.0/24"                     #small hack to be able to recreate subnets without conflict.
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.env}-${element(split(",",lookup(var.availability_zones, data.aws_region.current.name)), count.index)}"
  }
}

resource "aws_internet_gateway" "ig" {
  count  = var.count_vpc
  vpc_id = "${aws_vpc.vpc.0.id}"

  tags = {
    Name = "${var.env}"
  }
}

resource "aws_route_table" "rt" {
  count  = var.count_vpc
  vpc_id = "${aws_vpc.vpc.0.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ig.0.id}"
  }

  tags = {
    Name = "${var.env}"
  }
}

resource "aws_route_table_association" "rta" {
  count          = "${var.count_vpc == 0 ? 0 : length(split(",", lookup(var.availability_zones, data.aws_region.current.name)))}"
  subnet_id      = "${aws_subnet.subnet.0.id}"
  route_table_id = "${aws_route_table.rt.0.id}"
}
