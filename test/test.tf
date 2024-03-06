module "aws_deploy-test" {
  source         = "../"
  env            = var.env_name
  user_data_file = "user_data.bash"

  static_nodes   = 1
  spot_nodes     = 1
  spot_nodes_min = 1
  spot_nodes_max = 2

  instance_type  = "t3.large"
  instance_types = ["m5.large", "r5.large"]
  ami_name       = "aeternity-ubuntu-22.04-v1709639419"

  additional_storage      = true
  additional_storage_size = 5

  enable_state_channels = true
  enable_internal_api   = true

  tags = {
    env   = var.env_name
    envid = coalesce(var.envid, var.env_name)
    role  = "aenode"
    color = "black"
  }

  config_tags = {
    bootstrap_version = var.bootstrap_version
    vault_addr        = var.vault_addr
    vault_role        = "ae-node"
    bootstrap_config  = "secret2/aenode/config/${var.env_name}"
  }
}
