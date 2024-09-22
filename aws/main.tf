terraform {
  required_version = "= 1.8.1"

  required_providers {
    aws = "= 4.51.0"
  }
}

provider "aws" {
  region = "ap-northeast-1"

  default_tags {
    tags = {
      Managed = "Terraform"
    }
  }
}

