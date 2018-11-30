terraform {
  required_version = "> 0.11.0"

  backend "gcs" {
    bucket  = "tf-state-ionosphere"
    prefix  = "terraform/state"
    project = "blockstream-store"
  }
}

provider "google" {
  project = "${var.project}"
}

module "blc" {
  source = "modules/blc"

  project           = "${var.project}"
  name              = "ionosphere-blc"
  network           = "default"
  region            = "us-west1"
  zone              = "us-west1-a"
  instance_type     = "custom-2-6144"
  announce_addr     = "${google_compute_address.ionosphere.*.address}"
  bitcoin_docker    = "${var.bitcoin_docker}"
  lightning_docker  = "${var.lightning_docker}"
  charge_docker     = "${var.charge_docker}"
  ionosphere_docker = "${var.ionosphere_docker}"
  net               = "testnet"
  data_image        = "${data.google_compute_image.ionosphere.self_link}"
}
