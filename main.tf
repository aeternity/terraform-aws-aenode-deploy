module "aws_vpc" {
  source = "./vpc"
  env    = var.env
}

module "aws_fleet" {
  source = "./fleet"
  env    = var.env

  vpc_id  = var.vpc_id != "" ? var.vpc_id : module.aws_vpc.vpc_id
  subnets = length(var.subnets) != 0 ? var.subnets : module.aws_vpc.subnets

  instance_type  = var.instance_type
  instance_types = var.instance_types
  ami_name       = var.ami_name

  user_data_file = var.user_data_file

  static_nodes   = var.static_nodes
  spot_nodes     = var.spot_nodes
  spot_nodes_min = var.spot_nodes_min
  spot_nodes_max = var.spot_nodes_max

  root_volume_size              = var.root_volume_size
  root_volume_iops              = var.root_volume_iops
  root_volume_throughput        = var.root_volume_throughput
  additional_storage            = var.additional_storage
  additional_storage_size       = var.additional_storage_size
  additional_storage_iops       = var.additional_storage_iops
  additional_storage_throughput = var.additional_storage_throughput

  enable_internal_api   = var.enable_internal_api
  enable_state_channels = var.enable_state_channels
  asg_target_groups     = var.asg_target_groups

  tags        = var.tags
  config_tags = var.config_tags
}
