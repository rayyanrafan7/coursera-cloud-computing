variable "imageid" {}
variable "instance-type" {}
variable "key-name" {}
variable "vpc_security_group_ids" {}
variable "cnt" {}
variable "install-env-file" {}

variable "az" {
  default = ["ca-central-1a", "ca-central-1b", "ca-central-1d"]
}

variable "elb-name" {}
variable "tg-name" {}
variable "asg-name" {}
variable "lt-name" {}

variable "min" {
  default = 2
}

variable "max" {
  default = 5
}

variable "desired" {
  default = 3
}

variable "module-tag" {}
variable "raw-s3-bucket" {}
variable "finished-s3-bucket" {}