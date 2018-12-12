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
  bitcoin_docker    = "${var.bitcoin_docker}"
  lightning_docker  = "${var.lightning_docker}"
  charge_docker     = "${var.charge_docker}"
  ionosphere_docker = "${var.ionosphere_docker}"
  net               = "testnet"

  # CI vars
  region        = "us-west1"
  zone          = "us-west1-a"
  instance_type = "custom-2-6144"
  host          = "satellite.blockstream.com"
  ssl_cert      = "https://www.googleapis.com/compute/v1/projects/blockstream-store/global/sslCertificates/ionosphere-12-03-2018"
}
