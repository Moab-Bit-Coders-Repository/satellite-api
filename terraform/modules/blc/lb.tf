# Forwarding rules
resource "google_compute_global_forwarding_rule" "rule-https" {
  name        = "ionosphere-https-forwarding-rule"
  target      = "${google_compute_target_https_proxy.https-proxy.self_link}"
  port_range  = "443"
  ip_protocol = "TCP"
  ip_address  = "${google_compute_global_address.lb.address}"
}

resource "google_compute_global_forwarding_rule" "rule-http" {
  name        = "ionosphere-http-forwarding-rule"
  target      = "${google_compute_target_http_proxy.http-proxy.self_link}"
  port_range  = "80"
  ip_protocol = "TCP"
  ip_address  = "${google_compute_global_address.lb.address}"
}

# Target proxies
resource "google_compute_target_http_proxy" "http-proxy" {
  name    = "ionosphere-http-proxy"
  url_map = "${google_compute_url_map.http.self_link}"
}

resource "google_compute_target_https_proxy" "https-proxy" {
  name             = "ionosphere-https-proxy"
  url_map          = "${google_compute_url_map.https.self_link}"
  ssl_certificates = ["${var.ssl_cert}"]
}

# URL maps
resource "google_compute_url_map" "http" {
  name            = "ionosphere-http-urlmap"
  default_service = "${google_compute_backend_service.blc.self_link}"

  host_rule {
    hosts        = ["${var.host}"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = "${google_compute_backend_service.blc.self_link}"

    path_rule {
      paths   = ["/*"]
      service = "${google_compute_backend_service.blc.self_link}"
    }
  }
}

resource "google_compute_url_map" "https" {
  name            = "ionosphere-https-urlmap"
  default_service = "${google_compute_backend_service.blc.self_link}"

  host_rule {
    hosts        = ["${var.host}"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = "${google_compute_backend_service.blc.self_link}"

    path_rule {
      paths   = ["/*"]
      service = "${google_compute_backend_service.blc.self_link}"
    }
  }
}
