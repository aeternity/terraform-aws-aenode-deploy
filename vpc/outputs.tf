output "subnets" {
  value = "${aws_subnet.subnet.*.id}"
}

output "vpc_id" {
  value = "${aws_vpc.vpc.0.id}"
}
