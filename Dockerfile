FROM eclipse-temurin:25-jre-noble

ARG MINECRAFT_SERVER_URL="https://piston-data.mojang.com/v1/objects/97ccd4c0ed3f81bbb7bfacddd1090b0c56f9bc51/server.jar"

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates bash \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/minecraft /data

RUN curl -L "$MINECRAFT_SERVER_URL" -o /opt/minecraft/server.jar

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /data

EXPOSE 25565/tcp

ENTRYPOINT ["/entrypoint.sh"]
