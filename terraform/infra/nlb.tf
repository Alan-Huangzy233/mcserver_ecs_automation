resource "aws_lb" "minecraft" {
  name                             = "mc-ecs-nlb"
  internal                         = false
  load_balancer_type               = "network"
  subnets                          = data.aws_subnets.default.ids
  enable_cross_zone_load_balancing = true

  tags = {
    Name    = "${var.project_name}-nlb"
    Project = var.project_name
    Managed = "terraform"
  }
}

resource "aws_lb_target_group" "minecraft" {
  name                 = "mc-ecs-tg"
  port                 = var.minecraft_port
  protocol             = "TCP"
  target_type          = "ip"
  vpc_id               = data.aws_vpc.default.id
  deregistration_delay = 30

  health_check {
    protocol            = "TCP"
    port                = "traffic-port"
    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name    = "${var.project_name}-tg"
    Project = var.project_name
    Managed = "terraform"
  }
}

resource "aws_lb_listener" "minecraft" {
  load_balancer_arn = aws_lb.minecraft.arn
  port              = var.minecraft_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.minecraft.arn
  }
}
