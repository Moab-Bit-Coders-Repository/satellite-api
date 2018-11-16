variable "project" {
  type    = "string"
  default = "blockstream-store"
}

variable "boot_image" {
  type    = "string"
  default = "cos-cloud/cos-stable"
}

variable "name" {
  type = "string"
}

variable "bitcoin_docker" {
  type = "string"
}

variable "charge_docker" {
  type = "string"
}

variable "lightning_docker" {
  type = "string"
}

variable "ionosphere_docker" {
  type = "string"
}

variable "announce_addr" {
  type = "list"
}

variable "network" {
  type = "string"
}

variable "region" {
  type = "string"
}

variable "zone" {
  type = "string"
}

variable "instance_type" {
  type = "string"
}

variable "data_image" {
  type = "string"
}

variable "net" {
  type = "string"
}
