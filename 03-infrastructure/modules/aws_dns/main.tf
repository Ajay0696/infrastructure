resource "aws_route53_record" "k8s_api" {
  zone_id = var.hosted_zone_id
  name    = var.api_server_dns_name
  type    = "A"

  alias {
    name                   = var.nlb_dns_name
    zone_id                = var.nlb_zone_id
    evaluate_target_health = true
  }
}
