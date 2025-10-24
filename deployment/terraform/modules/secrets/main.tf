# Secrets Manager Module

resource "aws_secretsmanager_secret" "main" {
  name        = var.secret_name
  description = "Secrets for ${var.environment} environment"
  
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "main" {
  secret_id     = aws_secretsmanager_secret.main.id
  secret_string = jsonencode(var.secrets)
}
