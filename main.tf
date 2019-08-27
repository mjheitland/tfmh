#--- root/main.tf ---
provider "aws" {
}

# deploy networking resources
module "networking" {
  source          = "./networking"
  vpc_cidr        = var.vpc_cidr
  public_cidrs    = var.public_cidrs
  private_cidrs   = var.private_cidrs
  accessip        = var.accessip
  service_ports   = var.service_ports
}

/*
# Deploy Compute Resources
module "compute" {
  source          = "./compute"
  instance_count  = "${var.instance_count}"
  key_name        = "${var.key_name}"
  public_key_path = "${var.public_key_path}"
  instance_type   = "${var.server_instance_type}"
  subnets         = "${module.networking.public_subnets}"
  security_group  = "${module.networking.public_sg}"
  subnet_ips      = "${module.networking.subnet_ips}"
}
*/