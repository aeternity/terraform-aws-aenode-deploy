locals {
  autoscale_enabled = var.spot_nodes_max > var.spot_nodes_min
  user_data         = templatefile("${path.module}/templates/${var.user_data_file}", {})
  instance_types    = concat([var.instance_type], var.instance_types)
  lb_attachements   = setproduct(var.asg_target_groups, range(0, var.static_nodes))
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
  user_data            = var.user_data != "" ? var.user_data : local.user_data
  subnet_id            = element(var.subnets, 1)
  ebs_optimized        = true
  iam_instance_profile = "ae-node"

  vpc_security_group_ids = [
    aws_security_group.ae-nodes.id,
    aws_security_group.ae-nodes-management.id,
  ]

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    iops                  = var.root_volume_iops
    throughput            = var.root_volume_throughput
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.config_tags, {
    Name = "ae-${var.tags.env}-static-node",
    kind = "seed",
  }, var.tags)

  volume_tags = merge({
    Name = "ae-${var.tags.env}-static-node",
    kind = "seed",
  }, var.tags)
}

resource "aws_ebs_volume" "ebs" {
  count             = var.additional_storage ? var.static_nodes : 0
  availability_zone = element(aws_instance.static_node.*.availability_zone, count.index)
  type              = "gp3"
  size              = var.additional_storage_size
  iops              = var.additional_storage_iops
  throughput        = var.additional_storage_throughput

  tags = merge({
    Name = "ae-${var.tags.env}-static-node",
    kind = "seed",
  }, var.tags)
}

resource "aws_volume_attachment" "ebs_att" {
  count       = var.additional_storage ? var.static_nodes : 0
  device_name = "/dev/sdh"
  volume_id   = element(aws_ebs_volume.ebs.*.id, count.index)
  instance_id = element(aws_instance.static_node.*.id, count.index)
}

resource "aws_lb_target_group_attachment" "static_node" {
  for_each          = {for i,v in local.lb_attachements: i => v}
  target_group_arn  = each.value[0]
  target_id         = element(aws_instance.static_node.*.id, each.value[1])
}

resource "aws_launch_template" "fleet" {
  name_prefix   = "ae-${var.env}-tpl-"
  image_id      = data.aws_ami.ami.id
  instance_type = var.instance_type
  user_data     = base64encode(local.user_data)
  ebs_optimized = true

  vpc_security_group_ids = [
    aws_security_group.ae-nodes.id,
    aws_security_group.ae-nodes-management.id,
  ]

  iam_instance_profile {
    name = "ae-node"
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_type           = "gp3"
      volume_size           = var.root_volume_size
      iops                  = var.root_volume_iops
      throughput            = var.root_volume_throughput
      delete_on_termination = true
    }
  }

  dynamic "block_device_mappings" {
    for_each = var.additional_storage ? [1] : []
    content {
      device_name = "/dev/sdh"

      ebs {
        volume_type           = "gp3"
        volume_size           = var.additional_storage_size
        iops                  = var.additional_storage_iops
        throughput            = var.additional_storage_throughput
        delete_on_termination = true
      }
    }
  }

  dynamic "monitoring" {
    for_each = local.autoscale_enabled ? [1] : []
    content {
      enabled = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.config_tags, {
      Name = "ae-${var.tags.env}-node",
      kind = "peer",
    }, var.tags)
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge({
      Name = "ae-${var.tags.env}-node",
      kind = "peer",
    }, var.tags)
  }
}

resource "aws_autoscaling_group" "spot_fleet" {
  count               = var.spot_nodes_min > 0 ? 1 : 0
  name_prefix         = "ae-${var.env}-spot-nodes-"
  min_size            = max(var.spot_nodes_min, var.spot_nodes)
  max_size            = max(var.spot_nodes_max, var.spot_nodes)
  capacity_rebalance  = true
  vpc_zone_identifier = var.subnets
  target_group_arns   = var.asg_target_groups
  suspended_processes = var.asg_suspended_processes

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

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "capacity-optimized"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.fleet.id
        version            = "$Latest"
      }

      dynamic "override" {
        for_each = toset(local.instance_types)
        content {
          instance_type = override.key
        }
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "example" {
  count                  = local.autoscale_enabled ? 1 : 0
  name                   = "ae-${var.env}-capacity"
  autoscaling_group_name = aws_autoscaling_group.spot_fleet.0.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 50.0
  }
}
