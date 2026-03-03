# Generates capi_cluster.yaml with real VPC and subnet IDs after terraform apply
resource "local_file" "capi_cluster_manifest" {
  filename = "${path.module}/capi_cluster.yaml"
  content = templatefile("${path.module}/capi_cluster.yaml.tpl", {
    cluster_name            = local.cluster_name
    region                  = local.region
    ssh_key_name            = local.ssh_key_name
    vpc_id                  = aws_vpc.this.id
    subnet_ids              = [for s in aws_subnet.public : s.id]
    kubernetes_version      = local.kubernetes_version
    control_plane_count     = local.control_plane_count
    worker_count            = local.worker_count
    control_plane_instance  = local.control_plane_instance
    worker_instance         = local.worker_instance
  })
}
