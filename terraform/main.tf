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
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.minecraft_subnet.id
  vpc_security_group_ids = [aws_security_group.minecraft_sg.id]
  associate_public_ip_address = true
  key_name      = "devcraft"

  user_data = <<-EOF
  #!/bin/bash
apt-get update
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce

# Comprobando la instalación de Docker
if [ $(which docker) ]; then
    echo "Docker ha sido instalado correctamente."
else
    echo "Error: Docker no se pudo instalar."
    exit 1
fi

usermod -aG docker ubuntu
# Espera a que el usuario 'ubuntu' se configure correctamente antes de usarlo
while ! id ubuntu &>/dev/null; do
    echo "Esperando la configuración del usuario 'ubuntu'..."
    sleep 1
done

# Pull the Minecraft server Docker image
docker pull imurilloh/minecraft-server:latest

# Run the Minecraft server Docker container
docker run -d -p 25565:25565 --name minecraft_server imurilloh/minecraft-server:latest

# Opcional: Verificar si el contenedor está corriendo
if [ $(docker ps -q -f name=minecraft_server) ]; then
    echo "El servidor de Minecraft está corriendo."
else
    echo "Error: El servidor de Minecraft no está corriendo."
    exit 1
fi
EOF

  tags = {
    Name = "MinecraftServer"
    Project = "DevCraft"
  }
}

output "server_ip" {
  value = aws_instance.minecraft_server.public_ip
}
