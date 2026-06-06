output "account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.minecraft.name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.minecraft.name
}

output "efs_file_system_id" {
  description = "EFS file system ID used for Minecraft persistent data"
  value       = aws_efs_file_system.minecraft.id
}

output "nlb_dns_name" {
  description = "Public Network Load Balancer DNS name for the Minecraft server"
  value       = aws_lb.minecraft.dns_name
}

output "minecraft_server_address" {
  description = "Minecraft server address"
  value       = "${aws_lb.minecraft.dns_name}:25565"
}
