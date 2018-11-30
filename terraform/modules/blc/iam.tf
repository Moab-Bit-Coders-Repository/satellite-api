resource "google_service_account" "blc" {
  account_id   = "${var.name}"
  display_name = "${var.name}"
}

resource "google_project_iam_member" "blc" {
  project = "${var.project}"
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.blc.email}"
}
