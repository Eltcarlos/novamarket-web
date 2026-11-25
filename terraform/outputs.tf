output "network_id" {
  value = google_compute_network.main.id
}

output "app_subnets" {
  description = "Subred de aplicaciones por region."
  value       = { for r, s in google_compute_subnetwork.app : r => s.id }
}

output "nat_ips" {
  description = "IPs de salida para allowlist en terceros."
  value       = { for r, a in google_compute_address.nat : r => a.address }
}

output "deployer_email" {
  description = "Cuenta de servicio de despliegue."
  value       = google_service_account.deployer.email
}

output "run_web_urls" {
  description = "URL de Cloud Run por region (solo interno/LB; ya no acepta internet directo)."
  value       = { for r, s in google_cloud_run_v2_service.web : r => s.uri }
}

output "lb_ip" {
  description = "IP publica del ALB externo. Entrada real de la app (HTTP por ahora)."
  value       = google_compute_global_address.lb.address
}

output "artifact_registry_repos" {
  description = "Repo Docker de Artifact Registry por region."
  value       = { for r, repo in google_artifact_registry_repository.web : r => repo.id }
}
