variable "region" {
  default = "us-east-1"
}

variable "vpc_cidr" {
    type = string
    default = "10.50.0.0/16"
}

variable "public_subnets_cidr" {
    type = list(string)
    default = ["10.50.0.0/24", "10.50.16.0/24"]
}

variable "private_subnets_cidr" {
    type = list(string)
    default = ["10.50.32.0/24", "10.50.48.0/24"]
}
