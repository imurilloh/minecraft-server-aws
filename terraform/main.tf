terraform {
  backend "s3" {
    bucket = "devcraft-terraform-state"
    key    = "minecraft/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "minecraft_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "minecraft_vpc"
    Project = "DevCraft"
  }
}

resource "aws_internet_gateway" "minecraft_igw" {
  vpc_id = aws_vpc.minecraft_vpc.id

  tags = {
    Name = "minecraft_igw"
  }
}

resource "aws_route_table" "minecraft_rt" {
  vpc_id = aws_vpc.minecraft_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.minecraft_igw.id
  }

  tags = {
    Name = "minecraft_rt"
  }
}

resource "aws_subnet" "minecraft_subnet" {
  vpc_id     = aws_vpc.minecraft_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "minecraft_subnet"
    Project = "DevCraft"
  }
}

resource "aws_route_table_association" "minecraft_rta" {
  subnet_id      = aws_subnet.minecraft_subnet.id
  route_table_id = aws_route_table.minecraft_rt.id
}

resource "aws_security_group" "minecraft_sg" {
  vpc_id = aws_vpc.minecraft_vpc.id

  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "minecraft_sg"
    Project = "DevCraft"
  }
}

resource "aws_instance" "minecraft_server" {
  ami           = "ami-04b4f1a9cf54c11d0"
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.minecraft_subnet.id
  vpc_security_group_ids = [aws_security_group.minecraft_sg.id]
  associate_public_ip_address = true
  key_name      = "devcraft"

  user_data = <<-EOF
  #!/bin/bash
  sudo apt-get update && sudo apt-get upgrade -y

  # Instalar paquetes necesarios para permitir que apt use un repositorio sobre HTTPS
  sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

  # Agregar la clave GPG oficial de Docker
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

  # Agregar el repositorio de Docker a las fuentes de APT
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

  # Actualizar el índice de paquetes de apt e instalar la última versión de Docker Engine y containerd
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io

  # Agregar el usuario `ubuntu` al grupo `docker` para que pueda ejecutar comandos Docker sin sudo
  sudo usermod -aG docker ubuntu

  # Habilitar y arrancar el servicio de Docker
  sudo systemctl enable docker
  sudo systemctl start docker

  # Esperar a que Docker esté completamente iniciado
  while ! sudo docker info >/dev/null 2>&1; do
      echo "Waiting for Docker to launch..."
      sleep 1
  done

  # Instalar docker-compose
  sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose

  # Crear un archivo docker-compose.yml
  cat > /home/ubuntu/docker-compose.yml <<EOF
  version: '3.8'
  services:
    minecraft:
      image: imurilloh/minecraft-server:latest
      ports:
        - "25565:25565"
      volumes:
        - minecraft_data:/data
  volumes:
    minecraft_data:
EOF

# Ejecutar el servidor de Minecraft usando docker-compose
cd /home/ubuntu
sudo docker-compose up -d
EOF

  tags = {
    Name = "MinecraftServer"
    Project = "DevCraft"
  }
}

output "server_ip" {
  value = aws_instance.minecraft_server.public_ip
}
