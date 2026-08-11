output "cluster_security_group_id" {
  value = aws_eks_cluster.clusterpos.vpc_config[0].cluster_security_group_id
}