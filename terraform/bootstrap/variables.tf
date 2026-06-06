variable "aws_region" {
  description = "AWS region used for the project"
  type        = string
  default     = "us-east-1"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository for the Minecraft Docker image"
  type        = string
  default     = "minecraft-ecs-automation"
}
