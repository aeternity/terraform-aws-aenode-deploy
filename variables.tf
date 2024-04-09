variable "env" {}

variable "spot_nodes" {
  default = 0
}

variable "spot_nodes_min" {
  default = 0
}

variable "spot_nodes_max" {
  default = 0
}

# Keep 8GB as default root volume size, that is the same if no parameter is used
variable "root_volume_size" {
  description = "Number of gigabytes. Default to 8."
  default     = 8
}

variable "root_volume_iops" {
  description = "Guaranteed minimum IOPS. 3000 is free tier"
  default     = 3000
}

variable "root_volume_throughput" {
  description = "Number of megabytes per second limit. 125 is free tier"
  default     = 125
}

variable "additional_storage" {
  type    = bool
  default = false
}

variable "additional_storage_size" {
  default = 0
}

variable "additional_storage_iops" {
  default = 3000
}

variable "additional_storage_throughput" {
  default = 125
}

variable "static_nodes" {
  default = 0
}

variable "instance_type" {
  description = "Fleet insance type. Deprecated: Use instance_types."
}

variable "instance_types" {
  type = list(string)
}

variable "ami_name" {}

variable "user_data_file" {
  default = "user_data.bash"
}

variable "user_data" {
  type    = string
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
  type    = list(any)
  default = []
}

variable "asg_suspended_processes" {
  type    = list(string)
  default = ["AZRebalance"]
}

variable "vpc_id" {
  default = ""
}

variable "subnets" {
  type    = list(any)
  default = []
}

variable "tags" {
  type = map(string)
}

variable "config_tags" {
  type = map(string)
}

variable "prometheus_cidrs" {
  type    = list(string)
  default = ["3.123.140.48/32", "3.121.48.202/32", "3.69.159.53/32"]
}
