variable "env" {}

variable "envid" {
  default = ""
}

variable "kind" {
  default = ""
}

variable "color" {
  default = "unknown"
}

variable "bootstrap_version" {}

variable "spot_nodes" {
  default = 0
}

variable "spot_nodes_min" {
  default = 0
}

variable "spot_nodes_max" {
  default = 0
}

variable "additional_storage" {
  type    = bool
  default = false
}

variable "additional_storage_size" {
  default = 0
}

variable "static_nodes" {
  default = 0
}

variable "instance_type" {}

variable "spot_price" {}

variable "ami_name" {}

variable "vault_addr" {}

variable "vault_role" {
  type    = string
  default = "ae-node"
}

# Keep 8GB as default root volume size, that is the same if no parameter is used
variable "root_volume_size" {
  description = "Number of gigabytes. Default to 8."
  default     = 8
}

variable "user_data_file" {
  default = "user_data.bash"
}

variable "enable_state_channels" {
  type    = bool
  default = false
}

variable "enable_internal_api" {
  type    = bool
  default = false
}

variable "asg_target_groups" {
  type    = list(any)
  default = []
}

variable "node_config" {
  default = ""
}

variable "vpc_id" {
  default = ""
}

variable "subnets" {
  type    = list(any)
  default = []
}
