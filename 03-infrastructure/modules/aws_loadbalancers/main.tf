###############################################################################
# Network Load Balancer – Kubernetes API server
###############################################################################
resource "aws_lb" "k8s_api" {
  name               = var.lb_name
  internal           = var.internal
  load_balancer_type = "network"
  subnets            = var.subnet_ids

  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}_api-nlb"
  })
}

resource "aws_lb_target_group" "k8s_api" {
  # Target group name also has a 32-char limit
  name     = "${var.lb_name}-tg"
  port     = var.api_server_port
  protocol = "TCP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    protocol            = "TCP"
    port                = var.api_server_port
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}_api-tg"
  })
}

resource "aws_lb_listener" "k8s_api" {
  load_balancer_arn = aws_lb.k8s_api.arn
  port              = var.api_server_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s_api.arn
  }
}
