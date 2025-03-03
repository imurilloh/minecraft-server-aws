terraform {
  backend "s3" {
    bucket = "devcraft-terraform-state" # Nombre de tu bucket
    key    = "minecraft/terraform.tfstate" # Ruta dentro del bucket
    region = "us-east-1" # Región de tu bucket
  }
}

provider "aws" {
  region = "us-east-1"
}
resource "aws_vpc" "minecraft_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "minecraft_vpc"
    Project = "DevCraft"
  }
}

resource "aws_subnet" "minecraft_subnet" {
  vpc_id     = aws_vpc.minecraft_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true  # Habilita la asignación de IPs públicas
  tags = {
    Name = "minecraft_subnet"
    Project = "DevCraft"
  }
}

resource "aws_security_group" "minecraft_sg" {
  vpc_id = aws_vpc.minecraft_vpc.id

  ingress {
    from_port   = 25565
    to_port     = 25565
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
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.minecraft_subnet.id
  vpc_security_group_ids = [aws_security_group.minecraft_sg.id]
  associate_public_ip_address = true  # Asignar IP pública

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y apt-transport-https ca-certificates curl software-properties-common
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
              add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
              apt-get update
              apt-get install -y docker-ce
              usermod -aG docker ubuntu
              docker pull imurilloh/minecraft-server:latest
              docker run -d -p 25565:25565 --name minecraft_server imurilloh/minecraft-server:latest
              EOF

  tags = {
    Name = "MinecraftServer"
    Project = "DevCraft"
  }
}

output "server_ip" {
  value = aws_instance.minecraft_server.public_ip
}
