module "aws_deploy-test" {
  source            = "../"
  env               = "${var.env_name}"
  envid             = "${var.envid}"
  bootstrap_version = "${var.bootstrap_version}"
  vault_role        = "ae-node"
  vault_addr        = "${var.vault_addr}"
  user_data_file    = "user_data.bash"

  static_nodes   = 1
  spot_nodes     = 1
  spot_nodes_min = 1
  spot_nodes_max = 1

  spot_price    = "0.04"
  instance_type = "t3.large"
  ami_name      = "aeternity-ubuntu-16.04-*"

  additional_storage      = true
  additional_storage_size = 5

  aeternity = {
    package = "${var.package}"
  }

  enable_state_channels = true
  enable_internal_api   = true
}

module "aws_deploy-test_vpc" {
  source            = "../"
  env               = var.env_name
  envid             = "${var.envid}"
  bootstrap_version = "${var.bootstrap_version}"
  vault_role        = "ae-node"
  vault_addr        = "${var.vault_addr}"
  user_data_file    = "user_data.bash"
  vpc_id            = module.aws_deploy-test.vpc_id
  subnets           = module.aws_deploy-test.subnets
  create_vpc        = false

  static_nodes   = 1
  spot_nodes     = 1
  spot_nodes_min = 1
  spot_nodes_max = 1

  spot_price    = "0.04"
  instance_type = "t3.large"
  ami_name      = "aeternity-ubuntu-16.04-*"

  additional_storage      = true
  additional_storage_size = 5

  aeternity = {
    package = "${var.package}"
  }

  enable_state_channels = true
  enable_internal_api   = true
}
