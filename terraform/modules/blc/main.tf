# Individual resources

# Instance group
resource "google_compute_region_instance_group_manager" "blc" {
  name = "${var.name}-ig"

  base_instance_name = "${var.name}-ig-${count.index}"
  instance_template  = "${google_compute_instance_template.blc.self_link}"
  region             = "${var.region}"
  target_size        = 1
}

# Instance template
resource "google_compute_instance_template" "blc" {
  name_prefix  = "${var.name}-template-"
  description  = "This template is used to create ${var.name} instances."
  machine_type = "${var.instance_type}"

  labels {
    type = "lightning-app"
    name = "${var.name}"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    source_image = "${var.boot_image}"
    disk_type    = "pd-ssd"
    auto_delete  = true
    boot         = true
  }

  disk {
    source_image = "${var.data_image}"
    disk_type    = "pd-ssd"
    auto_delete  = false
    device_name  = "data"
  }

  network_interface {
    network = "${data.google_compute_network.blc.self_link}"

    access_config {
      nat_ip = "${element(var.announce_addr, count.index)}"
    }
  }

  metadata {
    google-logging-enabled = "true"
    "user-data"            = "${data.template_cloudinit_config.blc.rendered}"
  }

  service_account {
    email  = "${google_service_account.blc.email}"
    scopes = ["compute-ro", "storage-ro"]
  }

  lifecycle {
    create_before_destroy = true
  }
}
