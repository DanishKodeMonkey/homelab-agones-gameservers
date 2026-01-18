#!/bin/sh
set -eu

CONFIG_FILE="${CONFIG_FILE:-starbound_server.config}"
CONFIG_DIR="${CONFIG_DIR:-/data/storage}"
TEMPLATE_CONFIG="/config/template.config"
MODS_DIR="/data/mods"
MODS_SERVER_DIR="/data/assets"

# ---- Copy Config at Startup ----
mkdir -p "$CONFIG_DIR"

if [ -s "$TEMPLATE_CONFIG" ]; then
    echo "Applying template config to $CONFIG_DIR/$CONFIG_FILE"
    cp "$TEMPLATE_CONFIG" "$CONFIG_DIR/$CONFIG_FILE"
else
    echo "WARNING: Template config $TEMPLATE_CONFIG is missing or empty!"
fi

# --- mods

# Make sure the user assets directory exists
mkdir -p "$MODS_SERVER_DIR"

# Copy mods
if [ -d "$MODS_DIR" ]; then
  echo "[Info] Copying mods from $MODS_DIR to $MODS_SERVER_DIR..."
  cp -u "$MODS_DIR"/*.pak "$MODS_SERVER_DIR/" 2>/dev/null || true
else
  echo "[Info] No mods folder found at $MODS_DIR"
fi

# Optional: list copied mods
echo "[Info] Mods currently in $MODS_SERVER_DIR:"
ls -1 "$MODS_SERVER_DIR" || true

# --- Start game server
/data/linux/starbound_server -bootconfig /data/storage/starbound_server.config &
GAME_PID=$!

# Tell Agones we are ready
curl -X POST http://localhost:${AGONES_SDK_HTTP_PORT:-9358}/ready -d '{}'

# Health loop
while kill -0 $GAME_PID 2>/dev/null; do
  curl -X POST http://localhost:${AGONES_SDK_HTTP_PORT:-9358}/health -d '{}'
  sleep 5
done

# Tell Agones we are shutting down
curl -X POST http://localhost:${AGONES_SDK_HTTP_PORT:-9358}/shutdown -d '{}'

wait $GAME_PID
