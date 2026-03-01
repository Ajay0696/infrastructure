###############################################################################
# API server – A alias record → API NLB
# Record: api.mgmt-cluster.us-east-2.ajayshandbook.com
###############################################################################
resource "aws_route53_record" "api" {
  zone_id = local.hosted_zone_id
  name    = "api.${local.dns_base}"
  type    = "A"

  alias {
    name                   = module.lb.nlb_dns_name
    zone_id                = module.lb.nlb_zone_id
    evaluate_target_health = true
  }
}

###############################################################################
# Ingress app DNS records – A alias → Ingress NLB → Traefik
# Add app names to local.ingress_apps in locals.tf to create new records.
# Creates: <app>.mgmt-cluster.us-east-2.ajayshandbook.com
###############################################################################
resource "aws_route53_record" "ingress_apps" {
  for_each = toset(local.ingress_apps)

  zone_id = local.hosted_zone_id
  name    = "${each.key}.${local.dns_base}"
  type    = "A"

  alias {
    name                   = aws_lb.ingress.dns_name
    zone_id                = aws_lb.ingress.zone_id
    evaluate_target_health = true
  }
}
