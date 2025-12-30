variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "host" {
  description = "Hostname of the Infisical instance"
  type        = string
}

variable "encryption_key" {
  description = "Infisical encryption key (generate with: openssl rand -base64 32)"
  type        = string
  sensitive   = true
}

variable "auth_secret" {
  description = "Infisical auth secret (generate with: openssl rand -base64 32)"
  type        = string
  sensitive   = true
}

variable "db_connection_uri" {
  description = "PostgreSQL connection URI"
  type        = string
  sensitive   = true
}

variable "redis_url" {
  description = "Redis connection URL"
  type        = string
  sensitive   = true
}

variable "smtp_username" {
  description = "SMTP authentication username (e.g., postmaster@example.mailgun.org)"
  type        = string
  sensitive   = true
}

variable "smtp_password" {
  description = "SMTP authentication password"
  type        = string
  sensitive   = true
}
