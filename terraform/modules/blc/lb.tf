# Forwarding rules
resource "google_compute_forwarding_rule" "ionosphere-https" {
  name        = "${var.name}-https"
  target      = "${google_compute_target_pool.ionosphere.self_link}"
  port_range  = "443"
  ip_protocol = "TCP"
  ip_address  = "${google_compute_address.ionosphere.address}"
}

resource "google_compute_forwarding_rule" "ionosphere-http" {
  name        = "${var.name}-http"
  target      = "${google_compute_target_pool.ionosphere.self_link}"
  port_range  = "80"
  ip_protocol = "TCP"
  ip_address  = "${google_compute_address.ionosphere.address}"
}

resource "google_compute_target_pool" "ionosphere" {
  name   = "${var.name}-proxy"
  region = "${var.region}"

  health_checks = [
    "${google_compute_http_health_check.blc-http.self_link}",
  ]
}
