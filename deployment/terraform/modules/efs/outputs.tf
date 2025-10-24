output "file_system_id" {
  description = "ID of the EFS file system"
  value       = aws_efs_file_system.main.id
}

output "access_point_id" {
  description = "ID of the EFS access point"
  value       = aws_efs_access_point.chromadb.id
}

output "security_group_id" {
  description = "ID of the EFS security group"
  value       = aws_security_group.efs.id
}
