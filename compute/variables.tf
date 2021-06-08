variable "region" {
  description = "AWS region"
  type        = string
}
variable "project_name" {
  description = "project name is used as resource tag"
  type        = string
}
variable "key_name" {
  description = "name of keypair to access ec2 instances"
  type        = string
}
variable "public_key_path" {
  description = "file path on deployment machine to public rsa key to access ec2 instances"
  type        = string
}
variable "instance_type" {
  description = "type of ec2 instance"
  type        = string
}
variable "vpc_id" {
  description = "id of vpc"
  type        = string
}
variable "subpub_ids" {
  description = "ids of public subnets"
  type        = list(string)
}
variable "sg_id" {
  description = "id of security group"
  type        = string
}
