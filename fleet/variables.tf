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

variable "env" {}

variable "instance_type" {
  description = "Fleet insance type. Deprecated: Use instance_types."
}

variable "instance_types" {
  type = list(string)
}

variable "vpc_id" {}

variable "subnets" {
  type = list(any)
}

variable "ami_name" {}

variable "user_data_file" {}

variable "user_data" {
  type = string
  default = ""
}

variable "enable_state_channels" {
  type    = bool
  default = false
}

variable "enable_internal_api" {
  type    = bool
  default = false
}

variable "enable_mdw" {
  type    = bool
  default = false
}

variable "asg_target_groups" {
  type = list(any)
}

variable "asg_suspended_processes" {
  type    = list(string)
  default = []
}

variable "tags" {
  type = map(string)
}

variable "config_tags" {
  type = map(string)
}
