# --- ALB externo (global) -> Cloud Run en ambas regiones ---------------------
# Cloud Run ya no acepta trafico de internet directo (INGRESS_TRAFFIC_INTERNAL_
# LOAD_BALANCER); este es el unico camino de entrada publico. Sin dominio
# todavia: HTTP en el puerto 80. Agregar certificado administrado + proxy HTTPS
# cuando haya un dominio apuntando a la IP de abajo.

resource "google_compute_region_network_endpoint_group" "web" {
  for_each = var.regions

  name                  = "${var.name_prefix}-web-neg-${each.key}"
  region                = each.key
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = google_cloud_run_v2_service.web[each.key].name
  }
}

resource "google_compute_backend_service" "web" {
  name                  = "${var.name_prefix}-web"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTP"

  dynamic "backend" {
    for_each = var.regions
    content {
      group = google_compute_region_network_endpoint_group.web[backend.key].id
    }
  }
}

resource "google_compute_url_map" "web" {
  name            = "${var.name_prefix}-web"
  default_service = google_compute_backend_service.web.id
}

resource "google_compute_target_http_proxy" "web" {
  name    = "${var.name_prefix}-web"
  url_map = google_compute_url_map.web.id
}

resource "google_compute_global_address" "lb" {
  name         = "${var.name_prefix}-web-lb"
  address_type = "EXTERNAL"
}

resource "google_compute_global_forwarding_rule" "web" {
  name                  = "${var.name_prefix}-web"
  ip_address            = google_compute_global_address.lb.address
  ip_protocol           = "TCP"
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  target                = google_compute_target_http_proxy.web.id

  depends_on = [google_project_service.required]
}
