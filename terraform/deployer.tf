# --- Cuenta de despliegue (CI/CD) --------------------------------------------
# Sin llaves: Cloud Build la usa como service account del trigger, y el humano
# la impersona para gcloud deploy/build manuales. No tiene roles propios aqui;
# los roles se otorgan en iam.tf.

resource "google_service_account" "deployer" {
  account_id   = "novamarket-deployer"
  display_name = "NovaMarket deployer"
  description  = "Solo despliegues. Sin llaves: se usa por impersonacion."

  depends_on = [google_project_service.required]
}

resource "google_service_account_iam_member" "deployer_impersonation" {
  for_each = var.deployer_impersonators

  service_account_id = google_service_account.deployer.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = each.value
}
