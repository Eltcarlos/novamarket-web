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
