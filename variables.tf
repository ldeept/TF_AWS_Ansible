variable "profile" {
  type    = string
  default = "default"
}

variable "region-master" {
  type    = string
  default = "us-east-1"
}

variable "region-slave" {
  type    = string
  default = "us-west-2"
}

variable "external_ip" {
  type    = string
  default = "0.0.0.0/0"
}

variable "slave-count" {
  type    = number
  default = 2
}

variable "instance-type" {
  type    = string
  default = "t3.micro"
}

#variable "subnets" {
#  type = number
#  default = {
#    "us-west-2a" = 1
#    "us-west-2b" = 2
#    "us-west-2c" = 3
#  }
#}
