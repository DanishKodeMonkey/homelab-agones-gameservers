#!/bin/sh
set -eu

echo "===== GameServer Init Script ====="

# ---- Sanity checks ----
MISSING_VARS=0

STEAM_LOGIN_MODE="${STEAM_LOGIN_MODE:-anonymous}"

if [ "$STEAM_LOGIN_MODE" = "credentials" ]; then
  if [ -z "${STEAM_USERNAME:-}" ]; then
    echo "ERROR: STEAM_USERNAME not set"
    MISSING_VARS=1
  fi

  if [ -z "${STEAM_PASSWORD:-}" ]; then
    echo "ERROR: STEAM_PASSWORD not set"
    MISSING_VARS=1
  fi
fi

if [ -z "${STEAM_APPID:-}" ]; then
  echo "ERROR: STEAM_APPID not set"
  MISSING_VARS=1
fi

if [ -z "${CONFIG_DIR:-}" ]; then
  echo "ERROR: CONFIG_DIR not set"
  MISSING_VARS=1
fi

if [ -z "${CONFIG_FILE:-}" ]; then
  echo "ERROR: CONFIG_FILE not set"
  MISSING_VARS=1
fi

if [ "$MISSING_VARS" -ne 0 ]; then
  echo "One or more required environment variables are missing. Continuing for debug..."
fi

echo "== SteamCMD Install Phase =="

if [ ! -d /data/steamapps ]; then
  echo "Game install not found, installing via SteamCMD..."

  if [ "$STEAM_LOGIN_MODE" = "anonymous" ]; then
    /home/steam/steamcmd/steamcmd.sh \
      +force_install_dir /data \
      +login anonymous \
      +app_update "${STEAM_APPID:-}" validate \
      +quit
  else
    /home/steam/steamcmd/steamcmd.sh \
      +force_install_dir /data \
      +login "${STEAM_USERNAME:-}" "${STEAM_PASSWORD:-}" \
      +app_update "${STEAM_APPID:-}" validate \
      +quit
  fi

  echo "SteamCMD install completed"
else
  echo "Game already installed, skipping install"
fi

echo "== Config Bootstrap Phase =="

mkdir -p "${CONFIG_DIR:-/data}"

if [ ! -s "/config/template.config" ]; then
  echo "ERROR: /config/template.config is missing or empty!"
  echo "Listing /config for debug:"
  ls -l /config || true
else
  echo "Template config exists"
fi

if [ ! -f "${CONFIG_DIR:-/data}/${CONFIG_FILE:-server.config}" ]; then
  echo "Config not found, copying default config"
  cp /config/template.config "${CONFIG_DIR:-/data}/${CONFIG_FILE:-server.config}" || echo "Failed to copy template config"
else
  echo "Config already exists at ${CONFIG_DIR:-/data}/${CONFIG_FILE:-server.config}, leaving untouched"
fi

echo "===== Init Completed (debug mode) ====="
