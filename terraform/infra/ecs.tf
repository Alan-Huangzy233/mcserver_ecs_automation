resource "aws_cloudwatch_log_group" "minecraft" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7

  tags = {
    Project = var.project_name
    Managed = "terraform"
  }
}

resource "aws_ecs_cluster" "minecraft" {
  name = "${var.project_name}-cluster"

  tags = {
    Project = var.project_name
    Managed = "terraform"
  }
}

resource "aws_ecs_task_definition" "minecraft" {
  family                   = "${var.project_name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = data.aws_iam_role.lab_role.arn
  task_role_arn            = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([
    {
      name      = "minecraft"
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = var.minecraft_port
          hostPort      = var.minecraft_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "MINECRAFT_MEMORY"
          value = var.minecraft_memory
        },
        {
          name  = "MINECRAFT_PORT"
          value = tostring(var.minecraft_port)
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "minecraft_data"
          containerPath = "/data"
          readOnly      = false
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.minecraft.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "minecraft"
        }
      }
    }
  ])

  volume {
    name = "minecraft_data"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.minecraft.id
      root_directory     = "/"
      transit_encryption = "ENABLED"
    }
  }

  depends_on = [
    aws_efs_mount_target.minecraft,
    aws_cloudwatch_log_group.minecraft
  ]

  tags = {
    Project = var.project_name
    Managed = "terraform"
  }
}

resource "aws_ecs_service" "minecraft" {
  name                               = "${var.project_name}-service"
  cluster                            = aws_ecs_cluster.minecraft.id
  task_definition                    = aws_ecs_task_definition.minecraft.arn
  desired_count                      = var.desired_count
  launch_type                        = "FARGATE"
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.minecraft.arn
    container_name   = "minecraft"
    container_port   = var.minecraft_port
  }

  depends_on = [
    aws_lb_listener.minecraft
  ]

  tags = {
    Project = var.project_name
    Managed = "terraform"
  }
}
