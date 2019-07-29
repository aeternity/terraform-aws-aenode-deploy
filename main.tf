module "aws_vpc" {
  source = "./vpc"
  env    = "${var.env}"
}

module "aws_fleet" {
  source = "./fleet"
  color  = "${var.color}"
  env    = "${var.env}"
  envid  = "${var.envid}"

  vpc_id  = "${module.aws_vpc.vpc_id}"
  subnets = "${module.aws_vpc.subnets}"

  instance_type = "${var.instance_type}"
  ami_name      = "${var.ami_name}"
  spot_price    = "${var.spot_price}"

  vault_addr = "${var.vault_addr}"
  vault_role = "${var.vault_role}"

  bootstrap_version = "${var.bootstrap_version}"
  user_data_file    = "${var.user_data_file}"

  static_nodes   = "${var.static_nodes}"
  spot_nodes     = "${var.spot_nodes}"
  spot_nodes_min = "${var.spot_nodes_min}"
  spot_nodes_max = "${var.spot_nodes_max}"

  root_volume_size        = "${var.root_volume_size}"
  additional_storage      = "${var.additional_storage}"
  additional_storage_size = "${var.additional_storage_size}"

  aeternity             = "${var.aeternity}"
  enable_internal_api   = "${var.enable_internal_api}"
  enable_state_channels = "${var.enable_state_channels}"
  asg_target_groups     = "${var.asg_target_groups}"
}
