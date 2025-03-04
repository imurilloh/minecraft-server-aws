provider "aws" {
  region = var.region
}

module "network" {
  source = "./modules/network"
}

module "minecraft_server" {
  source        = "./modules/minecraft_server"
  subnet_id     = module.network.subnet_id
  sg_id         = module.network.sg_id
  instance_type = var.instance_type
  ami_id        = var.ami_id
}

output "minecraft_server_ip" {
  value = module.minecraft_server.server_ip
}