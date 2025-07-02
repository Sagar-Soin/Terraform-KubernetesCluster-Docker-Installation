terraform {
  required_version = "1.10.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.58.0"
    }
  }
  #   backend "s3" {
  #     bucket = "ssoin4"
  #     key    = "terraform.tfstate"
  #     region = "ap-south-1"
  #   }
}


provider "aws" {
  profile = "vaws"
  region  = "ap-south-1"
}