variable "aws_region" {
  description = "AWS region used for the project"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for AWS resources"
  type        = string
  default     = "minecraft-ecs-automation"
}

variable "container_image" {
  description = "Full Docker image URI for the Minecraft server container"
  type        = string
}

variable "minecraft_port" {
  description = "Minecraft Java server TCP port"
  type        = number
  default     = 25565
}

variable "minecraft_memory" {
  description = "Minecraft JVM memory setting"
  type        = string
  default     = "1024M"
}

variable "task_cpu" {
  description = "Fargate task CPU units"
  type        = number
  default     = 1024
}

variable "task_memory" {
  description = "Fargate task memory in MiB"
  type        = number
  default     = 2048
}

variable "desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 1
}

variable "lab_role_name" {
  description = "AWS Academy Learner Lab role used by ECS tasks"
  type        = string
  default     = "LabRole"
}
