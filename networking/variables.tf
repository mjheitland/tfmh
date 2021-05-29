#--- networking/variables.tf ---
variable "project_name" {
  description = "project name is used as resource tag"
  type        = string
}
variable "vpc_cidr" {
  description = "separate vpc for this project"
  type        = string
}
variable "subpub_cidrs" {
  description = "cidr blocks for public subnets"
  type        = list(string)
}
variable "subprv_cidrs" {
  description = "cidr blocks for private subnets"
  type        = list(string)
}
variable "access_ip" {
  description = "cidr block for incoming traffic"
  type        = string
}
variable "service_ports" {
  description = "ports that we open on our ec2 instance"
  type = list(object({
    from_port = number
    to_port   = number
  }))
}
