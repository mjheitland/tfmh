#--- root/outputs.tf ---
output "project_name" {
  value = var.project_name
}

#--- networking
output "vpc_id" {
  value = module.networking.vpc_id
}
output "igw_id" {
  value = module.networking.igw_id
}
output "subpub_ids" {
  value = module.networking.subpub_ids
}
output "subprv_ids" {
  value = module.networking.subprv_ids
}
output "sg_id" {
  value = module.networking.sg_id
}
output "rtpub_ids" {
  value = module.networking.rtpub_ids
}
output "rtprv_ids" {
  value = module.networking.rtprv_ids
}

#--- compute

output "alb_dns" {
  value = module.compute.alb_dns
}
output "alb_name" {
  value = module.compute.alb_name
}
output "asg_name" {
  value = module.compute.asg_name
}
output "ec2_windows" {
  value = module.compute.ec2_windows
}