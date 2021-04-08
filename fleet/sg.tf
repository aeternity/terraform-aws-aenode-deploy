resource "random_id" "sg_name" {
  byte_length = 4
}

resource "aws_security_group" "ae-nodes" {
  name   = "ae-${var.env}-nodes ${random_id.sg_name.hex}"
  vpc_id = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "local_in" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "TCP"
  security_group_id        = aws_security_group.ae-nodes.id
  source_security_group_id = aws_security_group.ae-nodes.id
}

resource "aws_security_group_rule" "external_api_in" {
  type              = "ingress"
  from_port         = 3013
  to_port           = 3013
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ae-nodes.id
}

resource "aws_security_group_rule" "internal_api_in" {
  count             = var.enable_internal_api ? 1 : 0
  type              = "ingress"
  from_port         = 3113
  to_port           = 3113
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ae-nodes.id
}

resource "aws_security_group_rule" "sc_websocket_in" {
  count             = var.enable_state_channels ? 1 : 0
  type              = "ingress"
  from_port         = 3014
  to_port           = 3014
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ae-nodes.id
}

resource "aws_security_group_rule" "sc_noise_in" {
  count             = var.enable_state_channels ? 1 : 0
  type              = "ingress"
  from_port         = 3114
  to_port           = 3114
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ae-nodes.id
}

resource "aws_security_group_rule" "sync_in" {
  type              = "ingress"
  from_port         = 3015
  to_port           = 3015
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ae-nodes.id
}

resource "aws_security_group_rule" "health_check_in" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ae-nodes.id
}

resource "aws_security_group_rule" "all_out" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ae-nodes.id
}

resource "aws_security_group" "ae-nodes-management" {
  name   = "ae-${var.env}-management ${random_id.sg_name.hex}"
  vpc_id = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "management-ssh_in" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ae-nodes-management.id
}

resource "aws_security_group_rule" "management-icmp_in" {
  type              = "ingress"
  from_port         = 8
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ae-nodes-management.id
}

resource "aws_security_group_rule" "management-all_out" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ae-nodes-management.id
}

resource "aws_security_group_rule" "management-ntp_out" {
  type              = "egress"
  from_port         = 123
  to_port           = 123
  protocol          = "UDP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ae-nodes-management.id
}
