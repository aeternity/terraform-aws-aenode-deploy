variable "static_nodes" {}

variable "spot_nodes" {
  default = 0
}

variable "spot_nodes_min" {
  default = 0
}

variable "spot_nodes_max" {
  default = 0
}

variable "root_volume_size" {}
variable "root_volume_iops" {}
variable "root_volume_throughput" {}

variable "additional_storage" {
  type    = bool
  default = false
}

variable "additional_storage_size" {}
variable "additional_storage_iops" {}
variable "additional_storage_throughput" {}

variable "color" {}

variable "env" {}

variable "envid" {
  default = ""
}

variable "bootstrap_version" {}

variable "instance_type" {}

variable "spot_price" {}

variable "vpc_id" {}

variable "subnets" {
  type = list(any)
}

variable "ami_name" {}

variable "vault_addr" {}

variable "vault_role" {}

variable "user_data_file" {}

variable "enable_state_channels" {
  type    = bool
  default = false
}

variable "enable_internal_api" {
  type    = bool
  default = false
}

variable "asg_target_groups" {
  type = list(any)
}

variable "node_config" {
  default = ""
}

variable "kind" {
  default = ""
}
