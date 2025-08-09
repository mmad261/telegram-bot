#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVICE_NAME="telegram-bot"
PYTHON="python3"
VENV_DIR="$PROJECT_DIR/.venv"

# Ensure apt metadata is fresh (no harm if already fresh)
sudo apt-get update -y

# Install minimal deps for venv & runtime
sudo apt-get install -y python3-venv python3-full

# Create venv if missing
if [ ! -d "$VENV_DIR" ]; then
  echo "[+] Creating virtualenv at $VENV_DIR"
  "$PYTHON" -m venv "$VENV_DIR"
fi

# Activate venv and upgrade installers
source "$VENV_DIR/bin/activate"
pip install --upgrade pip setuptools wheel

# Install project requirements if the file exists
if [ -f "$PROJECT_DIR/requirements.txt" ]; then
  echo "[+] Installing requirements.txt"
  pip install -r "$PROJECT_DIR/requirements.txt"
else
  echo "[!] No requirements.txt found. Skipping Python deps."
fi

# Create .env from example if needed
if [ -f "$PROJECT_DIR/.env.example" ] && [ ! -f "$PROJECT_DIR/.env" ]; then
  cp "$PROJECT_DIR/.env.example" "$PROJECT_DIR/.env"
  echo "[+] Created .env from .env.example. Please edit your secrets."
fi

# Write systemd unit
UNIT_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
echo "[+] Writing systemd unit: $UNIT_FILE"

sudo tee "$UNIT_FILE" >/dev/null <<UNIT
[Unit]
Description=Telegram Bot (${SERVICE_NAME})
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${USER}
WorkingDirectory=${PROJECT_DIR}
Environment=PYTHONUNBUFFERED=1
EnvironmentFile=-${PROJECT_DIR}/.env
ExecStart=${VENV_DIR}/bin/python ${PROJECT_DIR}/bot.py
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
UNIT

# Reload & start
sudo systemctl daemon-reload
sudo systemctl enable --now "$SERVICE_NAME"

# Show status summary
sleep 1
systemctl --no-pager --full status "$SERVICE_NAME" || true

echo "\n✅ Install finished. Logs: sudo journalctl -u ${SERVICE_NAME} -f"
