variable "project_name" { type = string }
variable "eks_cluster_name" { type = string }
variable "eks_version" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "node_instance_type" { type = string }
variable "node_desired_size" { type = number }
variable "node_min_size" { type = number }
variable "node_max_size" { type = number }