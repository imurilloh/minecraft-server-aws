# Usar una imagen base de Java (Minecraft requiere Java)
FROM openjdk:17-jdk-slim

# Crear directorio de trabajo
WORKDIR /minecraft

# Descargar el servidor oficial de Minecraft (ajusta la versión según necesites)
RUN apt-get update && apt-get install -y wget \
    && wget https://piston-data.mojang.com/v1/objects/8f3112a1049751cc472ec13e397eade5336ca7ae/server.jar

# Aceptar el EULA de Minecraft
RUN echo "eula=true" > eula.txt

# Exponer el puerto por defecto de Minecraft
EXPOSE 25565

# Comando para iniciar el servidor
CMD ["java", "-Xmx1024M", "-Xms1024M", "-jar", "server.jar", "nogui"]
