terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.53.0"
    }
  }
}

provider "aws" {
  region = terraform.workspace
  # region  = "ap-northeast-1"
  profile = "kcul"
}
