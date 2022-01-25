output "static_node_ips" {
  value = module.aws_fleet.static_node_ips
}

output "sg_id" {
  value = module.aws_fleet.sg_id
}

output "subnets" {
  value = module.aws_vpc.subnets
}

output "vpc_id" {
  value = module.aws_vpc.vpc_id
}
