# --- Artifact Registry -------------------------------------------------------
# Un repo Docker por region: la imagen vive cerca del Cloud Run que la consume.

resource "google_artifact_registry_repository" "web" {
  for_each = var.regions

  location      = each.key
  repository_id = "${var.name_prefix}-web"
  format        = "DOCKER"
  description   = "Imagenes de ${var.name_prefix}-web para Cloud Run."

  depends_on = [google_project_service.required]
}
