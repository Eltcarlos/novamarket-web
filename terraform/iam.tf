# --- IAM del pipeline Cloud Build -> Artifact Registry -> Cloud Run ------------
# Todo a nivel de recurso: la cuenta asignada no puede modificar el IAM del
# proyecto, y ademas asi el deployer solo alcanza lo que despliega.

resource "google_artifact_registry_repository_iam_member" "deployer_writer" {
  for_each = var.regions

  location   = each.key
  repository = google_artifact_registry_repository.web[each.key].name
  role       = "roles/artifactregistry.writer"
  member     = google_service_account.deployer.member
}

resource "google_cloud_run_v2_service_iam_member" "deployer_developer" {
  for_each = var.regions

  location = each.key
  name     = google_cloud_run_v2_service.web[each.key].name
  role     = "roles/run.developer"
  member   = google_service_account.deployer.member
}

# Publicar revisiones que corren con la identidad de runtime.
resource "google_service_account_iam_member" "deployer_act_as_run_web" {
  service_account_id = google_service_account.run_web.name
  role               = "roles/iam.serviceAccountUser"
  member             = google_service_account.deployer.member
}

# Tienda publica: cualquiera puede invocar, pero solo a traves del ALB
# (ingress = INTERNAL_LOAD_BALANCER en run.tf). Sin esto el ALB responde 403.
resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  for_each = var.regions

  location = each.key
  name     = google_cloud_run_v2_service.web[each.key].name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# --- Logs de build ---------------------------------------------------------------
# Escribir en Cloud Logging exige un rol de proyecto; se usa un bucket dedicado.

resource "google_storage_bucket" "build_logs" {
  name                        = "${var.project_id}-build-logs"
  location                    = var.primary_region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket_iam_member" "deployer_build_logs" {
  bucket = google_storage_bucket.build_logs.name
  role   = "roles/storage.admin" # solo sobre este bucket
  member = google_service_account.deployer.member
}
