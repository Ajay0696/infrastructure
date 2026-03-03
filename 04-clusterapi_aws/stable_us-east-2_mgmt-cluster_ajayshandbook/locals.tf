locals {
  project      = "ajayshandbook"
  environment  = "stable"
  region       = "us-east-2"
  cluster_name = "mgmt-cluster"

  # Naming convention: environment_region_clustername_projectname
  name_prefix = "${local.environment}_${local.region}_${local.cluster_name}_${local.project}"

  # VPC config
  vpc_cidr = "10.0.0.0/16"

  # Public subnets only (no NAT Gateway cost; nodes get public IPs)
  public_subnets = [
    { cidr = "10.0.0.0/24", az = "${local.region}a" },
    { cidr = "10.0.1.0/24", az = "${local.region}b" },
  ]

  # CAPI cluster config
  kubernetes_version      = "v1.31.0"
  control_plane_count     = 1
  worker_count            = 1
  control_plane_instance  = "t3a.medium"
  worker_instance         = "t3a.medium"
  ssh_key_name            = "ajayshandbook-key"

  common_tags = {
    Project     = local.project
    Environment = local.environment
    ClusterName = local.cluster_name
    ManagedBy   = "terraform"
  }
}
