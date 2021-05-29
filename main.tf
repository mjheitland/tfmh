#--- root/main.tf ---

# deploy networking resources
module "networking" {
  source = "./networking"

  project_name  = var.project_name
  vpc_cidr      = var.vpc_cidr
  subpub_cidrs  = var.subpub_cidrs
  subprv_cidrs  = var.subprv_cidrs
  access_ip     = var.access_ip
  service_ports = var.service_ports
}

# deploy compute resources
module "compute" {
  source = "./compute"

  region          = var.region
  project_name    = var.project_name
  key_name        = var.key_name
  public_key_path = var.public_key_path
  instance_type   = var.instance_type
  vpc_id          = module.networking.vpc_id
  subpub_ids      = module.networking.subpub_ids
  sg_id           = module.networking.sg_id
}
