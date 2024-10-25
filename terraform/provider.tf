terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.72.0"  
    }
  }

  required_version = ">= 1.0"
}


provider "aws" {
  region = var.aws_region
  profile = "terraform_user"

  default_tags {
    tags = var.default_tags
  }
}