terraform {
  required_version = "~> 0.14"
  required_providers {
    aws = ">= 3.0.0"
  }
  #  backend "s3" {
  #    key = "0_tfmh.tfstate"
  #  }
}

# default region: eu-west-1
provider "aws" {
  region = "eu-west-1"
}
