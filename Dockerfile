FROM openjdk:21-jdk-slim

WORKDIR /usr/src/minecraft

RUN apt-get update && apt-get install -y wget
RUN wget -O minecraft_server.jar https://piston-data.mojang.com/v1/objects/4707d00eb834b446575d89a61a11b5d548d8c001/server.jar
RUN echo "eula=true" > eula.txt
EXPOSE 25565

# Comando para iniciar el servidor
CMD ["java", "-Xmx1024M", "-Xms1024M", "-jar", "minecraft_server.jar", "nogui"]
