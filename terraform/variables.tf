variable "project" {
  type    = "string"
  default = "blockstream-store"
}

variable "ssl_cert" {
  type    = "string"
  default = ""
}

variable "host" {
  type    = "string"
  default = ""
}

# These could be overwritten by the ci with $CI_COMMIT_SHA, which is based on latest build
variable "bitcoin_docker" {
  type    = "string"
  default = "us.gcr.io/blockstream-store/bitcoind017@sha256:7577cd3cb0620ca9f6abffb3814dbb78b6faa1f8debf07d7dfd16cb192feecd9"
}

variable "lightning_docker" {
  type    = "string"
  default = "us.gcr.io/blockstream-store/lightningd@sha256:082d2d7d589ae83e01dfe8db9ef432e185c9f8a66b2ea063e9147921e181bf20"
}

variable "charge_docker" {
  type    = "string"
  default = "us.gcr.io/blockstream-store/charged@sha256:f13a7b0d4a81a2b9d45abc63d2d37846f3cb8e9e2f019ca1aa66475d73c2716f"
}

variable "ionosphere_docker" {
  type    = "string"
  default = "us.gcr.io/blockstream-store/ionosphere@sha256:32ad7042d8e457066eb0bb88f8df5f16ab97c0791c6ec8fdc5d3d49182f05ecb"
}
