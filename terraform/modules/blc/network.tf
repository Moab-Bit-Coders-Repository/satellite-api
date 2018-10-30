resource "google_compute_firewall" "blc" {
  name    = "ionosphere-fw-rule"
  network = "${data.google_compute_network.blc.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["18333", "18332", "9112"]
  }

  target_service_accounts = [
    "${google_service_account.blc.email}",
  ]
}
