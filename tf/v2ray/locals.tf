locals {
  # Workspace name -> AWS region
  regions = {
    tokyo     = "ap-northeast-1"
    seoul     = "ap-northeast-2"
    hongkong  = "ap-east-1"
    singapore = "ap-southeast-1"
    frankfurt = "eu-central-1"
  }
  region = local.regions[terraform.workspace]

  # SNI is always the host part of the REALITY dest
  reality_sni = split(":", var.reality_dest)[0]
}
