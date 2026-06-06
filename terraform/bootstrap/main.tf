resource "aws_ecr_repository" "minecraft" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project = "minecraft-ecs-automation"
    Managed = "terraform"
  }
}
