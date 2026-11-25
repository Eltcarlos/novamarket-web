# --- VPC -------------------------------------------------------------------

resource "google_compute_network" "main" {
  name                    = "${var.name_prefix}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL" # rutas dinamicas visibles entre regiones

  depends_on = [google_project_service.required]
}

resource "google_compute_subnetwork" "app" {
  for_each = var.regions

  name                     = "${var.name_prefix}-app-${each.key}"
  region                   = each.key
  network                  = google_compute_network.main.id
  ip_cidr_range            = each.value.app_cidr
  private_ip_google_access = true # APIs de Google sin IP publica

  log_config {
    aggregation_interval = "INTERVAL_5_MIN"
    flow_sampling        = 0.2 # muestreo para controlar el costo de logs
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# --- Acceso privado a Cloud SQL -------------------------------------------------
# Se usara Private Service Connect: un endpoint (IP interna) en la subred app por
# region, definido junto a la base de datos. No requiere peering ni el permiso
# servicenetworking.services.addPeering, no disponible en el proyecto asignado.

# --- Firewall ----------------------------------------------------------------
# GCP ya deniega el ingreso de forma implicita; esta regla lo hace auditable.
# No se abre ningun ingreso: Cloud Run y Cloud SQL no lo necesitan.

resource "google_compute_firewall" "deny_all_ingress" {
  name          = "${var.name_prefix}-deny-all-ingress"
  network       = google_compute_network.main.id
  direction     = "INGRESS"
  priority      = 65534
  source_ranges = ["0.0.0.0/0"]

  deny {
    protocol = "all"
  }

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# --- Cloud NAT (solo salida, IP fija) ----------------------------------------

resource "google_compute_router" "main" {
  for_each = var.enable_nat ? var.regions : {}

  name    = "${var.name_prefix}-router-${each.key}"
  region  = each.key
  network = google_compute_network.main.id
}

resource "google_compute_address" "nat" {
  for_each = var.enable_nat ? var.regions : {}

  name   = "${var.name_prefix}-nat-${each.key}"
  region = each.key

  depends_on = [google_project_service.required]
}

resource "google_compute_router_nat" "main" {
  for_each = var.enable_nat ? var.regions : {}

  name                               = "${var.name_prefix}-nat-${each.key}"
  region                             = each.key
  router                             = google_compute_router.main[each.key].name
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.nat[each.key].self_link]
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.app[each.key].id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
