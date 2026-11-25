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
