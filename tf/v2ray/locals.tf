locals {
  # Workspace name -> AWS region
  regions = {
    tokyo     = "ap-northeast-1"
    seoul     = "ap-northeast-2"
    frankfurt = "eu-central-1"
  }
  region = local.regions[terraform.workspace]
}
