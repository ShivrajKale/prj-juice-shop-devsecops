variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "juice-shop"
}

variable "vpc_cidr" {
    description = "CIDR block for the VPC"
    type        = string
    default     = "10.0.0.0/16"
}

variable "eks_cluster_name" {
    description = "Name of the EKS cluster"
    type        = string
    default     = "juice-shop-eks-cluster"
}

variable "eks_version" {
    description = "Kubernetes version for the EKS cluster"
    type        = string
    default     = "1.29"
}

variable "node_instance_type" {
    description = "EC2 instance type for EKS worker nodes"
    type        = string
    default     = "t3.medium"
}

variable "node_desired_size" {
    type = number
    default = 2
}

variable "node_min_size" {
    type = number
    default = 1
}

variable "node_max_size" {
    type = number
    default = 3
}