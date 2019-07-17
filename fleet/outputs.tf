output "static_node_ips" {
  value = "${aws_eip_association.ip_associate.*.public_ip}"
}

output "sg_id" {
  value = "${aws_security_group.ae-nodes.id}"
}
