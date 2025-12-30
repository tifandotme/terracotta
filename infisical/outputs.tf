output "service_url" {
  description = "Cloud Run service public URL"
  value       = google_cloud_run_v2_service.infisical.uri
}

output "infisical_deployment_summary" {
  description = "Summary of Infisical deployment configuration"
  value = {
    service_url     = google_cloud_run_v2_service.infisical.uri
    custom_domain   = var.host
    service_account = google_service_account.infisical.email
  }
}
