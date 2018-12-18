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

  project               = "${var.project}"
  name                  = "ionosphere-blc"
  network               = "default"
  bitcoin_docker        = "${var.bitcoin_docker}"
  lightning_docker      = "${var.lightning_docker}"
  charge_docker         = "${var.charge_docker}"
  ionosphere_docker     = "${var.ionosphere_docker}"
  ionosphere_sse_docker = "${var.ionosphere_sse_docker}"
  net                   = "testnet"

  # CI vars
  region        = "${var.region}"
  zone          = "${var.zone}"
  instance_type = "${var.instance_type}"
  host          = "${var.host}"
  ssl_cert      = "${var.ssl_cert}"
  timeout       = "${var.timeout}"
}
