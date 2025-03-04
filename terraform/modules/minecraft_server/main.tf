resource "aws_instance" "minecraft_server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [var.sg_id]
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
    sudo docker pull imurilloh/minecraft-server:latest
    sudo docker run -d -p 25565:25565 --name minecraft_server imurilloh/minecraft-server:latest
  EOF

  tags = {
    Name = "MinecraftServer"
    Project = "DevCraft"
  }
}

output "server_ip" {
  value = aws_instance.minecraft_server.public_ip
}