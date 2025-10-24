# ECS Cluster Module

resource "aws_ecs_cluster" "main" {
  name = var.cluster_name
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  
  tags = var.tags
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name
  
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
}
