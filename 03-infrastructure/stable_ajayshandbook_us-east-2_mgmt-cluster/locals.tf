locals {
  environment  = "stable"
  project      = "ajayshandbook"
  region       = "us-east-2"
  cluster_name = "mgmt-cluster"

  # Naming prefix used on every AWS resource tag/name
  # Pattern: environment_region_projectname
  name_prefix = "${local.environment}_${local.region}_${local.project}"

  # NLB name must be ≤32 chars and hyphens-only (no underscores)
  nlb_name = "stable-ajbk-mgmt-api"

  ###########################################################################
  # Networking
  ###########################################################################
  vpc_cidr            = "10.0.0.0/16"
  availability_zones  = ["us-east-2a", "us-east-2b"]
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  ###########################################################################
  # EC2 / ASG
  ###########################################################################
  instance_type = "t3a.medium"
  key_name      = "ajayshandbook-key" # Update to your EC2 key pair name

  # Control plane ASG sizing
  controlplane_desired = 1
  controlplane_min     = 1
  controlplane_max     = 3

  # Worker node ASG sizing
  worker_desired = 0
  worker_min     = 0
  worker_max     = 5

  ###########################################################################
  # Kubernetes
  ###########################################################################
  k8s_version      = "1.31"
  pod_network_cidr = "192.168.0.0/16" # Calico default – do not change without updating CNI
  service_cidr     = "10.96.0.0/12"
  api_server_port  = 6443

  ###########################################################################
  # DNS
  ###########################################################################
  domain         = "ajayshandbook.com"
  hosted_zone_id = "Z07061093OOVL6WYA3CA0"

  # Base suffix for all cluster DNS records
  # Results in: <service>.mgmt-cluster.us-east-2.ajayshandbook.com
  dns_base = "${local.cluster_name}.${local.region}.${local.domain}"

  # ── Ingress apps ──────────────────────────────────────────────────────────
  # Add app names here to create DNS A records → Ingress NLB → Traefik
  # Creates: <app>.mgmt-cluster.us-east-2.ajayshandbook.com
  ingress_apps = [
    "argocd",
    "grafana",
    "prometheus",
    "kubernetes-dashboard",
    "keycloak",
  ]

  # ── Ingress NLB port mappings ──────────────────────────────────────────────
  # LB listener port → Traefik NodePort on worker nodes
  ingress_ports = {
    http = {
      lb_port   = 80
      node_port = 30080
    }
    https = {
      lb_port   = 443
      node_port = 32443
    }
  }

  ###########################################################################
  # Common tags (merged into all resources via modules)
  ###########################################################################
  common_tags = {
    Environment = local.environment
    Project     = local.project
    Region      = local.region
    Cluster     = local.cluster_name
    ManagedBy   = "terraform"
  }
}
