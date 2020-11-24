#--- terraform.tfvars ---
project_name = "tfmh"
vpc_cidr     = "10.50.0.0/16"
subpub_cidrs = [
  "10.50.101.0/24"
  ,"10.50.102.0/24"
]
subprv_cidrs = [
  "10.50.201.0/24",
  "10.50.202.0/24"
]
access_ip     = "0.0.0.0/0"
service_ports = [
  { # ssh
    from_port = 22,
    to_port   = 22
  },
  { # web http
    from_port = 80,
    to_port   = 80
  },
  { # documentdb
    from_port = 27017, 
    to_port   = 27017
  } 
]

#--- compute
key_name        = "tfmh_key"
public_key_path = "./id_rsa.pub"
instance_type   = "t2.micro"
