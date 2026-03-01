###############################################################################
# Ingress NLB – sits in front of Traefik on worker nodes
###############################################################################
resource "aws_lb" "ingress" {
  name               = "stable-ajbk-mgmt-ingress"
  internal           = false
  load_balancer_type = "network"
  subnets            = module.vpc.public_subnet_ids

  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}_ingress-nlb"
  })
}

resource "aws_lb_target_group" "ingress" {
  for_each = local.ingress_ports

  name     = "stable-ajbk-ingress-${each.key}"
  port     = each.value.node_port
  protocol = "TCP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    enabled             = true
    protocol            = "TCP"
    port                = each.value.node_port
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}_ingress-${each.key}-tg"
  })
}

resource "aws_lb_listener" "ingress" {
  for_each = local.ingress_ports

  load_balancer_arn = aws_lb.ingress.arn
  port              = each.value.lb_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ingress[each.key].arn
  }
}

resource "aws_autoscaling_attachment" "ingress" {
  for_each = local.ingress_ports

  autoscaling_group_name = module.workers.asg_name
  lb_target_group_arn    = aws_lb_target_group.ingress[each.key].arn
}

output "ingress_nlb_dns_name" {
  description = "Ingress NLB DNS – Traefik entrypoint"
  value       = aws_lb.ingress.dns_name
}
