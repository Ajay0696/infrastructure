###############################################################################
# Launch Template
###############################################################################
resource "aws_launch_template" "main" {
  name_prefix   = "${var.name_prefix}_${var.role}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name != "" ? var.key_name : null
  user_data     = var.user_data != "" ? var.user_data : null

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = var.security_group_ids
    delete_on_termination       = true
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price                      = var.spot_max_price != "" ? var.spot_max_price : null
      instance_interruption_behavior = "terminate"
      spot_instance_type             = "one-time"
    }
  }

  # IMDSv2 required; hop limit 2 allows pods to reach IMDS via containerd
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.name_prefix}_${var.role}"
      Role = var.role
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.tags, {
      Name = "${var.name_prefix}_${var.role}-volume"
    })
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}_${var.role}-lt"
  })

  lifecycle {
    create_before_destroy = true
  }
}

###############################################################################
# Auto Scaling Group
###############################################################################
resource "aws_autoscaling_group" "main" {
  name                      = "${var.name_prefix}_${var.role}-asg"
  desired_capacity          = var.desired_capacity
  min_size                  = var.min_size
  max_size                  = var.max_size
  vpc_zone_identifier       = var.subnet_ids
  target_group_arns         = var.target_group_arns
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  dynamic "tag" {
    for_each = merge(var.tags, {
      Name                                           = "${var.name_prefix}_${var.role}"
      Role                                           = var.role
      "k8s.io/cluster-autoscaler/enabled"            = "true"
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
    })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}
