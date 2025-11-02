output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.main.certificate_authority[0].data
}

output "node_groups" {
  description = "All node groups created"
  value = {
    for name, ng in aws_eks_node_group.nodegroups : name => {
      name           = ng.node_group_name
      status         = ng.status
      instance_types = ng.instance_types
      capacity_type  = ng.capacity_type
    }
  }
}

output "cluster_security_group_id" {
  value = aws_security_group.eks_cluster_sg.id
}

output "node_security_group_id" {
  value = aws_security_group.eks_nodes_sg.id
}
