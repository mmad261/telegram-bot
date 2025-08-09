#!/usr/bin/env bash
set -euo pipefail
SERVICE_NAME="telegram-bot"

case "${1:-}" in
  start) sudo systemctl start "$SERVICE_NAME" ;;
  stop) sudo systemctl stop "$SERVICE_NAME" ;;
  restart) sudo systemctl restart "$SERVICE_NAME" ;;
  status) systemctl status "$SERVICE_NAME" ;;
  logs) sudo journalctl -u "$SERVICE_NAME" -f ;;
  *) echo "Usage: $0 {start|stop|restart|status|logs}"; exit 1 ;;
esac
