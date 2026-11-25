# --- Cloud Deploy -------------------------------------------------------------
# Un target por region (Cloud Run activo-activo) y un pipeline de una sola etapa
# por target: sin ambiente de staging por ahora, se despliega directo a prod.

resource "google_clouddeploy_target" "web" {
  for_each = var.regions

  name     = "${var.name_prefix}-web-${each.key}"
  location = var.primary_region

  run {
    location = "projects/${var.project_id}/locations/${each.key}"
  }

  require_approval = false

  depends_on = [google_project_service.required]
}

resource "google_clouddeploy_delivery_pipeline" "web" {
  name     = "${var.name_prefix}-web"
  location = var.primary_region

  serial_pipeline {
    dynamic "stages" {
      for_each = var.regions
      content {
        target_id = google_clouddeploy_target.web[stages.key].name
      }
    }
  }

  depends_on = [google_project_service.required]
}

# --- Cloud Build ---------------------------------------------------------------
# Trigger clasico (GitHub App) sobre el repo donde vive el codigo de la app web.
# El repo ya esta conectado a Cloud Build fuera de Terraform. Este bloque
# representa el trigger "triggernovamarket" creado manualmente en la consola
# (id fa14f800-4df7-4c36-996f-81198085ed76); se importa, no se vuelve a crear.

resource "google_cloudbuild_trigger" "web" {
  name     = "triggernovamarket"
  location = "global"
  tags     = ["qa", "novamarket"]

  service_account = google_service_account.deployer.id

  github {
    owner = "Eltcarlos"
    name  = "novamarket-web"

    push {
      branch = "^main$"
    }
  }

  # El provider exige build/filename/git_file_source explicito; autodetect en
  # la consola equivale a buscar este archivo en la raiz del repo.
  filename = "cloudbuild.yaml"

  depends_on = [google_project_service.required]
}
