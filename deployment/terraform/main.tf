# Knowledge Pipeline Infrastructure - Main Configuration

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Optional: Configure backend for state management
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "knowledge-pipeline/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "KnowledgePipeline"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# VPC Configuration
module "vpc" {
  source = "./modules/vpc"
  
  environment         = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  
  tags = var.tags
}

# ECS Cluster
module "ecs" {
  source = "./modules/ecs"
  
  environment        = var.environment
  cluster_name       = "${var.project_name}-${var.environment}"
  
  tags = var.tags
}

# EFS for ChromaDB persistence
module "efs" {
  source = "./modules/efs"
  
  environment         = var.environment
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  
  tags = var.tags
}

# Application Load Balancer
module "alb" {
  source = "./modules/alb"
  
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  certificate_arn    = var.certificate_arn
  
  tags = var.tags
}

# ECS Service for Knowledge Pipeline API
module "knowledge_pipeline_service" {
  source = "./modules/ecs-service"
  
  environment        = var.environment
  service_name       = "knowledge-pipeline-api"
  cluster_id         = module.ecs.cluster_id
  
  # Container configuration
  container_image    = var.knowledge_pipeline_image
  container_port     = 8000
  desired_count      = var.desired_count
  
  # Networking
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  alb_target_group_arn = module.alb.target_group_arn
  
  # EFS mount for ChromaDB
  efs_file_system_id = module.efs.file_system_id
  efs_access_point_id = module.efs.access_point_id
  
  # Auto-scaling
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity
  
  # Environment variables
  environment_variables = {
    ENVIRONMENT          = var.environment
    CHROMADB_PERSIST_DIR = "/mnt/efs/chromadb"
    EMBEDDING_MODEL      = "all-MiniLM-L6-v2"
    LOG_LEVEL           = "INFO"
  }
  
  # Secrets
  secrets_arns = [
    module.secrets.secret_arn
  ]
  
  tags = var.tags
}

# Secrets Manager for API keys and configuration
module "secrets" {
  source = "./modules/secrets"
  
  environment  = var.environment
  secret_name  = "${var.project_name}-${var.environment}-secrets"
  
  secrets = {
    api_key = var.api_key
  }
  
  tags = var.tags
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "knowledge_pipeline" {
  name              = "/aws/ecs/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days
  
  tags = var.tags
}

# CloudWatch Alarms
module "cloudwatch_alarms" {
  source = "./modules/cloudwatch"
  
  environment    = var.environment
  cluster_name   = module.ecs.cluster_name
  service_name   = "knowledge-pipeline-api"
  alb_arn_suffix = module.alb.alb_arn_suffix
  
  alarm_email    = var.alarm_email
  
  tags = var.tags
}

# Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.dns_name
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "efs_file_system_id" {
  description = "ID of the EFS file system"
  value       = module.efs.file_system_id
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}
