terraform {
  backend "s3" {
    bucket = "devcraft-terraform-state"
    key    = "minecraft/terraform.tfstate"
    region = "us-east-1"
  }
}