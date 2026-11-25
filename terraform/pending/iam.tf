# --- IAM para el pipeline Cloud Build -> Artifact Registry -> Cloud Deploy ---
# El trigger corre como google_service_account.deployer (no la SA default de
# Cloud Build), asi que los permisos del build van ahi.

data "google_project" "current" {}

locals {
  clouddeploy_sa = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-clouddeploy.iam.gserviceaccount.com"
}

# El build corre como deployer: necesita escribir logs, subir la imagen y
# crear el release de Cloud Deploy.
resource "google_project_iam_member" "deployer_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = google_service_account.deployer.member
}

resource "google_project_iam_member" "deployer_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = google_service_account.deployer.member
}

resource "google_project_iam_member" "deployer_clouddeploy_releaser" {
  project = var.project_id
  role    = "roles/clouddeploy.releaser"
  member  = google_service_account.deployer.member
}

# Crear la atestacion en si (firmar con KMS y adjuntarla a la note son
# permisos aparte, otorgados junto a sus recursos en binauthz.tf).
resource "google_project_iam_member" "deployer_containeranalysis_editor" {
  project = var.project_id
  role    = "roles/containeranalysis.occurrences.editor"
  member  = google_service_account.deployer.member
}

# El rollout en si lo ejecuta el service agent de Cloud Deploy, no deployer.
resource "google_project_iam_member" "clouddeploy_run_developer" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = local.clouddeploy_sa
}

# Cloud Deploy necesita "actuar como" la cuenta de runtime del servicio para
# poder desplegar revisiones que corren con esa identidad.
resource "google_service_account_iam_member" "clouddeploy_act_as_run_web" {
  service_account_id = google_service_account.run_web.name
  role               = "roles/iam.serviceAccountUser"
  member             = local.clouddeploy_sa
}
