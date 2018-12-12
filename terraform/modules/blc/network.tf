# IP addresses
resource "google_compute_address" "ionosphere" {
  name    = "ionosphere-external-ip-${count.index}"
  project = "${var.project}"
  region  = "${var.region}"
  count   = 1
}

resource "google_compute_global_address" "lb" {
  name    = "ionosphere-client-lb"
  project = "${var.project}"
}

resource "google_compute_firewall" "blc" {
  name    = "ionosphere-fw-rule"
  network = "${data.google_compute_network.blc.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["18333", "18332", "9735", "80"]
  }

  target_service_accounts = [
    "${google_service_account.blc.email}",
  ]
}

# Backend service
resource "google_compute_backend_service" "blc" {
  name        = "${var.name}-backend-service"
  description = "Ionosphere"
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 15

  backend {
    group = "${google_compute_instance_group_manager.blc.instance_group}"
  }

  health_checks = ["${google_compute_health_check.blc.self_link}"]
}

# Health checks
resource "google_compute_health_check" "blc" {
  name = "${var.name}-health-check"

  check_interval_sec = 5
  timeout_sec        = 3

  tcp_health_check {
    port = "80"
  }
}
