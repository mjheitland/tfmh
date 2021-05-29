terraform {
  required_version = "~> 0.14"
  required_providers {
    aws = ">= 3.0.0"
  }
  #  backend "s3" {
  #    key = "0_tfmh.tfstate"
  #  }
}

provider "aws" {
  region  = var.region
  profile = "default"
}
