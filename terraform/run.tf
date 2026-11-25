# --- Cloud Run (web app) ------------------------------------------------------

resource "google_service_account" "run_web" {
  account_id   = "${var.name_prefix}-web-run"
  display_name = "Runtime de ${var.name_prefix}-web en Cloud Run"
}

resource "google_cloud_run_v2_service" "web" {
  for_each = var.regions

  name                = "${var.name_prefix}-web-${each.key}"
  location            = each.key
  deletion_protection = false

  # Nada de internet directo: solo trafico interno a la VPC y trafico que
  # llega via un Load Balancer con Serverless NEG (el ALB externo en lb.tf).
  ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  binary_authorization {
    use_default = true
  }

  template {
    service_account = google_service_account.run_web.email

    # Egreso por la subred app de la region, para llegar a Cloud SQL via PSC y
    # para que el trafico de salida publico (APIs de pago) salga por el Cloud NAT
    # de IP fija en lugar de una IP efimera de Google.
    vpc_access {
      network_interfaces {
        network    = google_compute_network.main.id
        subnetwork = google_compute_subnetwork.app[each.key].id
      }
      egress = "ALL_TRAFFIC"
    }

    containers {
      # Placeholder de arranque: Cloud Build sustituye esta imagen en cada despliegue.
      image = "us-docker.pkg.dev/cloudrun/container/hello"

      ports {
        container_port = 8080
      }
    }
  }

  lifecycle {
    # La imagen la cambia Cloud Build; gcloud tambien actualiza client/client_version.
    ignore_changes = [
      template[0].containers[0].image,
      client,
      client_version,
    ]
  }

  depends_on = [google_project_service.required]
}
