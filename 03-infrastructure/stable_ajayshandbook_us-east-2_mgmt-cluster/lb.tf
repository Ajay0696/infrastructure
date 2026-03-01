module "lb" {
  source = "../modules/aws_loadbalancers"

  name_prefix = local.name_prefix
  lb_name     = local.nlb_name
  vpc_id      = module.vpc.vpc_id

  # Internet-facing NLB – API server reachable from anywhere (auth via kubeconfig certs)
  subnet_ids = module.vpc.public_subnet_ids
  internal   = false

  api_server_port = local.api_server_port

  tags = local.common_tags
}
