### Cluster EKS ###

resource "aws_eks_cluster" "clusterpos" {
  name     = "clusterpos"
  role_arn = var.lab_role_arn
  version  = "1.32"

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true  # <- adicione isso
  }

  vpc_config {
    subnet_ids         = var.subnets
    security_group_ids = [var.grupodeseguranca]
    endpoint_private_access = true   
    endpoint_public_access  = true 
  }
}

### Access Entry para o Node Group ###

resource "aws_eks_access_entry" "nodegrouppos" {
  cluster_name  = aws_eks_cluster.clusterpos.name
  principal_arn = var.lab_role_arn
  type          = "EC2_LINUX"               # tipo específico para worker nodes

  depends_on = [aws_eks_cluster.clusterpos]
}

### Node Group EKS ###

resource "aws_eks_node_group" "nodegrouppos" {
  cluster_name    = aws_eks_cluster.clusterpos.name
  node_group_name = "nodegrouppos"
  node_role_arn   = var.lab_role_arn
  subnet_ids      = var.subnets

  instance_types = var.instance_types

  scaling_config {
    desired_size = 1
    max_size     = 4
    min_size     = 1
  }

  depends_on = [
    aws_eks_cluster.clusterpos,
    aws_eks_access_entry.nodegrouppos   # <- node group só sobe após o access entry
  ]
}