output "ecr_repository_url"      { value = module.ecr.repository_url }
output "eks_cluster_name"        { value = module.eks.cluster_name }
output "alb_controller_role_arn" { value = module.eks.alb_controller_role_arn }
output "update_kubeconfig"       { value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${var.eks_cluster_name}" }