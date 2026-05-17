output "cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "alb_controller_role_arn" {
  value = aws_iam_role.alb_controller.arn
}