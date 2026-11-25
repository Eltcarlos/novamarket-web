resource "google_project_service" "required" {
  for_each = toset([
    "compute.googleapis.com",
  ])

  service            = each.key
  disable_on_destroy = false
}
