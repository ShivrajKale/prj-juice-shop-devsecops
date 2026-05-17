# terraform/modules/ecr/main.tf

resource "aws_ecr_repository" "juice_shop" {
  name                 = "${var.project_name}/juice-shop"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  image_scanning_configuration { scan_on_push = true }
}

resource "aws_ecr_lifecycle_policy" "juice_shop" {
  repository = aws_ecr_repository.juice_shop.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep only last 10 images"
      selection    = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 10 }
      action       = { type = "expire" }
    }]
  })
}