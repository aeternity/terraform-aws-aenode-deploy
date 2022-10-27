locals {
  autoscale_enabled = var.spot_nodes_max > var.spot_nodes_min
  node_config       = coalesce(var.node_config, "secret/aenode/config/${var.env}")
  user_data         = templatefile("${path.module}/templates/${var.user_data_file}", {})
}

data "aws_region" "current" {}

data "aws_ami" "ami" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_name]
  }

  owners = ["self"]
}

resource "aws_instance" "static_node" {
  count                = var.static_nodes
  ami                  = data.aws_ami.ami.id
  instance_type        = var.instance_type
  iam_instance_profile = "ae-node"

  root_block_device {
    volume_type = "gp2"
    volume_size = var.root_volume_size
  }

  tags = {
    Name              = "ae-${var.env}-static-node"
    env               = var.env
    node_config       = local.node_config
    envid             = var.envid
    role              = "aenode"
    color             = var.color
    kind              = coalesce(var.kind, "seed")
    bootstrap_version = var.bootstrap_version
    vault_addr        = var.vault_addr
    vault_role        = var.vault_role
  }

  user_data = local.user_data

  subnet_id = element(var.subnets, 1)

  vpc_security_group_ids = [
    aws_security_group.ae-nodes.id,
    aws_security_group.ae-nodes-management.id,
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group_attachment" "static_node" {
  count            = length(var.asg_target_groups) != 0 ? var.static_nodes : 0
  target_group_arn = element(var.asg_target_groups, count.index)
  target_id        = element(aws_instance.static_node.*.id, count.index)
}

resource "aws_ebs_volume" "ebs" {
  count             = var.additional_storage ? var.static_nodes : 0
  availability_zone = element(aws_instance.static_node.*.availability_zone, count.index)
  size              = var.additional_storage_size

  tags = {
    Name = "ae-${var.env}-static-node"
    env  = var.env
  }
}

resource "aws_volume_attachment" "ebs_att" {
  count       = var.additional_storage ? var.static_nodes : 0
  device_name = "/dev/sdh"
  volume_id   = element(aws_ebs_volume.ebs.*.id, count.index)
  instance_id = element(aws_instance.static_node.*.id, count.index)
}

resource "aws_launch_configuration" "spot" {
  count                = var.spot_nodes_min > 0 ? 1 : 0
  name_prefix          = "ae-${var.env}-spot-nodes-"
  iam_instance_profile = "ae-node"
  image_id             = data.aws_ami.ami.id
  instance_type        = var.instance_type
  spot_price           = var.spot_price

  security_groups = [
    aws_security_group.ae-nodes.id,
    aws_security_group.ae-nodes-management.id,
  ]

  root_block_device {
    volume_type = "gp2"
    volume_size = var.root_volume_size
  }

  lifecycle {
    create_before_destroy = true
  }

  user_data = local.user_data
}

resource "aws_launch_configuration" "spot-with-additional-storage" {
  count                = var.spot_nodes_min > 0 ? 1 : 0
  name_prefix          = "ae-${var.env}-spot-nodes-"
  iam_instance_profile = "ae-node"
  image_id             = data.aws_ami.ami.id
  instance_type        = var.instance_type
  spot_price           = var.spot_price

  security_groups = [
    aws_security_group.ae-nodes.id,
    aws_security_group.ae-nodes-management.id,
  ]

  root_block_device {
    volume_type = "gp2"
    volume_size = var.root_volume_size
  }

  ebs_block_device {
    device_name = "/dev/sdh"
    volume_size = var.additional_storage_size
  }

  lifecycle {
    create_before_destroy = true
  }

  user_data = local.user_data
}

resource "aws_autoscaling_group" "spot_fleet" {
  count                = var.spot_nodes_min > 0 ? 1 : 0
  name_prefix          = "ae-${var.env}-spot-nodes-"
  min_size             = max(var.spot_nodes_min, var.spot_nodes)
  max_size             = max(var.spot_nodes_max, var.spot_nodes)
  launch_configuration = var.additional_storage ? aws_launch_configuration.spot-with-additional-storage.0.name : aws_launch_configuration.spot.0.name
  vpc_zone_identifier  = var.subnets
  target_group_arns    = var.asg_target_groups

  enabled_metrics = local.autoscale_enabled ? [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ] : []

  lifecycle {
    create_before_destroy = true
  }

  tags = [
    {
      key                 = "Name"
      value               = "ae-${var.env}-nodes"
      propagate_at_launch = true
    },
    {
      key                 = "kind"
      value               = coalesce(var.kind, "peer")
      propagate_at_launch = true
    },
    {
      key                 = "env"
      value               = var.env
      propagate_at_launch = true
    },
    {
      key                 = "node_config"
      value               = local.node_config
      propagate_at_launch = true
    },
    {
      key                 = "envid"
      value               = coalesce(var.envid, var.env)
      propagate_at_launch = true
    },
    {
      key                 = "role"
      value               = "aenode"
      propagate_at_launch = true
    },
    {
      key                 = "color"
      value               = var.color
      propagate_at_launch = true
    },
    {
      key                 = "bootstrap_version"
      value               = var.bootstrap_version
      propagate_at_launch = true
    },
    {
      key                 = "vault_addr"
      value               = var.vault_addr
      propagate_at_launch = true
    },
    {
      key                 = "vault_role"
      value               = var.vault_role
      propagate_at_launch = true
    },
  ]
}

resource "aws_autoscaling_policy" "gateway-cpu-policy-up" {
  count                  = local.autoscale_enabled ? 1 : 0
  name                   = "ae-${var.env}-cpu-up"
  autoscaling_group_name = aws_autoscaling_group.spot_fleet.0.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

resource "aws_autoscaling_policy" "gateway-cpu-policy-down" {
  count                  = local.autoscale_enabled ? 1 : 0
  name                   = "ae-${var.env}-cpu-down"
  autoscaling_group_name = aws_autoscaling_group.spot_fleet.0.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "gateway-cpu-alarm-up" {
  count               = local.autoscale_enabled ? 1 : 0
  alarm_name          = "ae-${var.env}-cpu-alarm-up"
  alarm_description   = "cpu-alarm-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "70"

  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.spot_fleet.0.name
  }

  actions_enabled = true
  alarm_actions   = aws_autoscaling_policy.gateway-cpu-policy-up.*.arn
}

resource "aws_cloudwatch_metric_alarm" "gateway-cpu-alarm-down" {
  count               = local.autoscale_enabled ? 1 : 0
  alarm_name          = "ae-${var.env}-cpu-alarm-down"
  alarm_description   = "cpu-alarm-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "50"

  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.spot_fleet.0.name
  }

  actions_enabled = true
  alarm_actions   = aws_autoscaling_policy.gateway-cpu-policy-down.*.arn
}
