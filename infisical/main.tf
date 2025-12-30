terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  container_port = 8080
}

# Enable Cloud Run API for domain mapping
resource "google_project_service" "run" {
  service            = "run.googleapis.com"
  disable_on_destroy = true
}

# Service account for Cloud Run
resource "google_service_account" "infisical" {
  account_id   = "infisical-cloudrun"
  display_name = "Infisical Cloud Run Service Account"
  description  = "Service account for Infisical Cloud Run deployment with Secret Manager access"
}

# Secret Manager secrets for sensitive configuration
resource "google_secret_manager_secret" "encryption_key" {
  secret_id = "infisical-encryption-key"
  replication {
    auto {}
  }
  labels = {
    app = "infisical"
  }
}

resource "google_secret_manager_secret_version" "encryption_key" {
  secret      = google_secret_manager_secret.encryption_key.id
  secret_data = var.encryption_key
}

resource "google_secret_manager_secret" "auth_secret" {
  secret_id = "infisical-auth-secret"
  replication {
    auto {}
  }
  labels = {
    app = "infisical"
  }
}

resource "google_secret_manager_secret_version" "auth_secret" {
  secret      = google_secret_manager_secret.auth_secret.id
  secret_data = var.auth_secret
}

resource "google_secret_manager_secret" "db_uri" {
  secret_id = "infisical-db-connection-uri"
  replication {
    auto {}
  }
  labels = {
    app = "infisical"
  }
}

resource "google_secret_manager_secret_version" "db_uri" {
  secret      = google_secret_manager_secret.db_uri.id
  secret_data = var.db_connection_uri
}

resource "google_secret_manager_secret" "redis_url" {
  secret_id = "infisical-redis-url"
  replication {
    auto {}
  }
  labels = {
    app = "infisical"
  }
}

resource "google_secret_manager_secret_version" "redis_url" {
  secret      = google_secret_manager_secret.redis_url.id
  secret_data = var.redis_url
}

resource "google_secret_manager_secret" "smtp_password" {
  secret_id = "infisical-smtp-password"
  replication {
    auto {}
  }
  labels = {
    app = "infisical"
  }
}

resource "google_secret_manager_secret_version" "smtp_password" {
  secret      = google_secret_manager_secret.smtp_password.id
  secret_data = var.smtp_password
}

# IAM bindings for service account to access secrets
resource "google_secret_manager_secret_iam_member" "encryption_key_access" {
  secret_id = google_secret_manager_secret.encryption_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.infisical.email}"
}

resource "google_secret_manager_secret_iam_member" "auth_secret_access" {
  secret_id = google_secret_manager_secret.auth_secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.infisical.email}"
}

resource "google_secret_manager_secret_iam_member" "db_uri_access" {
  secret_id = google_secret_manager_secret.db_uri.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.infisical.email}"
}

resource "google_secret_manager_secret_iam_member" "redis_url_access" {
  secret_id = google_secret_manager_secret.redis_url.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.infisical.email}"
}

resource "google_secret_manager_secret_iam_member" "smtp_password_access" {
  secret_id = google_secret_manager_secret.smtp_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.infisical.email}"
}

# Cloud Run service with hardcoded resource limits
resource "google_cloud_run_v2_service" "infisical" {
  name     = "infisical"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.infisical.email

    scaling {
      min_instance_count = 1
      max_instance_count = 10
    }

    timeout = "300s"

    containers {
      image = "infisical/infisical:latest"

      ports {
        container_port = local.container_port
      }

      # Hardcoded resource limits
      resources {
        limits = {
          cpu    = "1"
          memory = "1Gi"
        }
        cpu_idle = true
      }

      # Health check probe
      startup_probe {
        initial_delay_seconds = 0
        timeout_seconds       = 1
        period_seconds        = 3
        failure_threshold     = 3
        tcp_socket {
          port = local.container_port
        }
      }

      env {
        name  = "PORT"
        value = tostring(local.container_port)
      }
      env {
        name  = "SITE_URL"
        value = "https://${var.host}"
      }
      env {
        name  = "TELEMETRY_ENABLED"
        value = "false"
      }

      # SMTP configuration
      env {
        name  = "SMTP_HOST"
        value = "smtp.mailgun.org"
      }
      env {
        name  = "SMTP_PORT"
        value = tostring(587)
      }
      env {
        name  = "SMTP_USERNAME"
        value = var.smtp_username
      }
      env {
        name  = "SMTP_FROM_ADDRESS"
        value = var.smtp_username
      }
      env {
        name  = "SMTP_FROM_NAME"
        value = "Infisical"
      }

      # Secret references for sensitive data
      env {
        name = "ENCRYPTION_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.encryption_key.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "AUTH_SECRET"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.auth_secret.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "DB_CONNECTION_URI"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_uri.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "REDIS_URL"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.redis_url.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "SMTP_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.smtp_password.secret_id
            version = "latest"
          }
        }
      }
    }

    max_instance_request_concurrency = 80
  }

  depends_on = [
    google_secret_manager_secret_iam_member.encryption_key_access,
    google_secret_manager_secret_iam_member.auth_secret_access,
    google_secret_manager_secret_iam_member.db_uri_access,
    google_secret_manager_secret_iam_member.redis_url_access,
    google_secret_manager_secret_iam_member.smtp_password_access,
  ]
}

resource "google_cloud_run_v2_service_iam_member" "public_access" {
  count    = 1 # allow public access = 1 or 0
  name     = "infisical"
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_domain_mapping" "infisical_domain" {
  location = var.region
  name     = var.host

  metadata {
    namespace = var.project_id
  }

  spec {
    route_name = google_cloud_run_v2_service.infisical.name
  }

  depends_on = [google_project_service.run]
}
