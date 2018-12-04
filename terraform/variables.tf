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
  default = "us.gcr.io/blockstream-store/bitcoind017@sha256:95f33d3df18809cc5aab293a3fc01fc33e8fab63a5dc1d54af627ed7cffd9b37"
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
  default = "us.gcr.io/blockstream-store/ionosphere@sha256:3d4194ebb4dfbc3a0262a0b122aae058f0785c8723cf5498b293bade9ec26962"
}
