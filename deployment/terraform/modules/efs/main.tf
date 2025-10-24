# EFS Module for ChromaDB Persistence

resource "aws_efs_file_system" "main" {
  creation_token = "${var.environment}-chromadb-efs"
  encrypted      = true
  
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-chromadb-efs"
    }
  )
}

resource "aws_efs_mount_target" "main" {
  count           = length(var.private_subnet_ids)
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "chromadb" {
  file_system_id = aws_efs_file_system.main.id
  
  posix_user {
    uid = 1000
    gid = 1000
  }
  
  root_directory {
    path = "/chromadb"
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "755"
    }
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-chromadb-access-point"
    }
  )
}

resource "aws_security_group" "efs" {
  name        = "${var.environment}-efs-sg"
  description = "Security group for EFS"
  vpc_id      = var.vpc_id
  
  ingress {
    description = "NFS from VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-efs-sg"
    }
  )
}

data "aws_vpc" "main" {
  id = var.vpc_id
}
