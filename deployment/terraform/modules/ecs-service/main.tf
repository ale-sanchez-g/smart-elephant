# ECS Service Module - Placeholder
# This module would contain the ECS task definition and service configuration
# For brevity, this is a simplified version

resource "aws_ecs_task_definition" "main" {
  family                   = "${var.environment}-${var.service_name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn
  
  container_definitions = jsonencode([
    {
      name      = var.service_name
      image     = var.container_image
      essential = true
      
      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]
      
      environment = [
        for key, value in var.environment_variables : {
          name  = key
          value = value
        }
      ]
      
      mountPoints = [
        {
          sourceVolume  = "efs"
          containerPath = "/mnt/efs"
          readOnly      = false
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/aws/ecs/${var.environment}"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = var.service_name
        }
      }
    }
  ])
  
  volume {
    name = "efs"
    
    efs_volume_configuration {
      file_system_id     = var.efs_file_system_id
      transit_encryption = "ENABLED"
      
      authorization_config {
        access_point_id = var.efs_access_point_id
      }
    }
  }
  
  tags = var.tags
}

resource "aws_ecs_service" "main" {
  name            = var.service_name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }
  
  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = var.service_name
    container_port   = var.container_port
  }
  
  depends_on = [aws_iam_role.execution]
  
  tags = var.tags
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.environment}-${var.service_name}-ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id
  
  ingress {
    description = "Allow inbound from ALB"
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = var.tags
}

# IAM Roles
resource "aws_iam_role" "execution" {
  name = "${var.environment}-${var.service_name}-execution-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  name = "${var.environment}-${var.service_name}-task-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  
  tags = var.tags
}

data "aws_region" "current" {}
data "aws_vpc" "main" {
  id = var.vpc_id
}
