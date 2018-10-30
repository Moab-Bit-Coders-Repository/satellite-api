resource "google_compute_address" "ionosphere" {
  name    = "ionosphere-external-ip-${count.index}"
  project = "${var.project}"
  region  = "us-west1"
  count   = 1
}
