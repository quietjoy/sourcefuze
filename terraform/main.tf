locals {
    availability_zones = ["us-east-1a", "us-east-1b"]
}

module "networking" {
    source               = "./modules/networking"
    region               = "${var.region}"
    vpc_cidr             = "${var.vpc_cidr}"
    public_subnets_cidr  = "${var.public_subnets_cidr}"
    private_subnets_cidr = "${var.private_subnets_cidr}"
    availability_zones   = "${local.availability_zones}"
}

module "ecs" {
    source = "./modules/ecs"
    vpc_id = "${module.networking.vpc_id}"
    private_subnets = "${module.networking.private_subnets}"
    public_subnets = "${module.networking.public_subnets}"
}