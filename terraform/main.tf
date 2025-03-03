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
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    sudo usermod -aG docker ubuntu
    sudo systemctl enable docker
    sudo systemctl start docker

    while ! sudo docker info >/dev/null 2>&1; do
      echo "Waiting for Docker to launch..."
      sleep 1
    done
    sudo mkdir -p /minecraft_data
    sudo docker run -d -p 25565:25565 -v /minecraft_data:/data --name minecraft_server imurilloh/minecraft-server:latest
  
  EOF
  tags = {
    Name = "MinecraftServer"
    Project = "DevCraft"
  }
}

output "server_ip" {
  value = aws_instance.minecraft_server.public_ip
}
