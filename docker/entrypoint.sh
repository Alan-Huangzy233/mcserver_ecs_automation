#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="/data"
SERVER_JAR="/opt/minecraft/server.jar"
MEMORY="${MINECRAFT_MEMORY:-1024M}"
PORT="${MINECRAFT_PORT:-25565}"
MOTD="${MINECRAFT_MOTD:-Acme Corp Minecraft Server}"

cd "$DATA_DIR"

if [ ! -f eula.txt ]; then
  echo "eula=true" > eula.txt
fi

if [ ! -f server.properties ]; then
  cat > server.properties <<SERVERPROPERTIES
server-port=${PORT}
motd=${MOTD}
enable-command-block=false
online-mode=true
difficulty=easy
gamemode=survival
max-players=20
SERVERPROPERTIES
fi

PIPE="/tmp/minecraft.stdin"
rm -f "$PIPE"
mkfifo "$PIPE"

# Keep the FIFO open so the Minecraft process does not exit from stdin EOF.
exec 3<>"$PIPE"

shutdown_server() {
  echo "Received shutdown signal. Sending 'stop' to Minecraft server..."

  if [ -n "${SERVER_PID:-}" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
    printf "stop\n" >&3 || true
    wait "$SERVER_PID" || true
  fi

  exec 3>&-
  exit 0
}

trap shutdown_server SIGTERM SIGINT

java -Xmx"$MEMORY" -Xms"$MEMORY" -jar "$SERVER_JAR" nogui < "$PIPE" &
SERVER_PID=$!

wait "$SERVER_PID"
