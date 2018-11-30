data "google_compute_network" "blc" {
  name = "default"
}

data "template_file" "blc" {
  template = "${file("${path.module}/cloud-init/blc.yaml")}"

  vars {
    rpcuser           = "ionosphere"
    rpcpass           = "ionosphere-lightning-app"
    rpcport           = "${var.net == "testnet" ? "18332" : "8332"}"
    bitcoin_cmd       = "bitcoind ${var.net == "testnet" ? "-testnet" : ""} -printtoconsole"
    lightning_cmd     = "lightningd ${var.net == "testnet" ? "--testnet" : "--mainnet"} --conf=/root/.lightning/lightning.conf"
    announce_addr     = "${element(var.announce_addr, count.index)}"
    lightning_port    = 9735
    bitcoin_docker    = "${var.bitcoin_docker}"
    lightning_docker  = "${var.lightning_docker}"
    charge_docker     = "${var.charge_docker}"
    ionosphere_docker = "${var.ionosphere_docker}"
  }
}

data "template_cloudinit_config" "blc" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content      = "${data.template_file.blc.rendered}"
  }
}
