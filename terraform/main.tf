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

data "google_compute_image" "ionosphere" {
  family  = "btc-mainnet-testnet"
  project = "blockstream-store"
}

module "blc" {
  source = "modules/blc"

  project           = "${var.project}"
  name              = "ionosphere-blc"
  network           = "default"
  region            = "us-west1"                                                                                                      # ci vars
  zone              = "us-west1-a"                                                                                                    #
  instance_type     = "custom-2-6144"                                                                                                 #
  bitcoin_docker    = "${var.bitcoin_docker}"
  lightning_docker  = "${var.lightning_docker}"
  charge_docker     = "${var.charge_docker}"
  ionosphere_docker = "${var.ionosphere_docker}"
  net               = "testnet"
  data_image        = "${data.google_compute_image.ionosphere.self_link}"
  host              = "satellite.blockstream.com"                                                                                     #
  ssl_cert          = "https://www.googleapis.com/compute/v1/projects/blockstream-store/global/sslCertificates/ionosphere-12-03-2018" #
}
