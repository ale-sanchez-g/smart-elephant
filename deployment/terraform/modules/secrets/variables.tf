variable "environment" {
  description = "Environment name"
  type        = string
}

variable "secret_name" {
  description = "Name of the secret"
  type        = string
}

variable "secrets" {
  description = "Map of secrets"
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
