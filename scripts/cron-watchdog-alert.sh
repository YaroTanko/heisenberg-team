#!/bin/bash
# cron-watchdog-alert.sh — Runs cron-watchdog and sends Telegram alert on failure
# Scheduled via LaunchAgent every 4 hours. Zero LLM tokens.

SCRIPTS_DIR="$(dirname "$0")"
LOG_DIR="$HOME/.openclaw/logs"
LOG_FILE="$LOG_DIR/cron-watchdog-alert.log"
mkdir -p "$LOG_DIR"

# Telegram config (kaizen bot)
BOT_TOKEN=$(python3 -c "
import json
with open('$HOME/.openclaw/openclaw.json') as f:
    cfg = json.load(f)
print(cfg['channels']['telegram']['accounts']['kaizen']['botToken'])
" 2>/dev/null)
CHAT_ID=622376

send_telegram() {
  local msg="$1"
  curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}" \
    -d "text=${msg}" \
    -d "parse_mode=Markdown" > /dev/null 2>&1
}

echo "$(date '+%Y-%m-%d %H:%M:%S') Running watchdog..." >> "$LOG_FILE"

RESULT=$(bash "$SCRIPTS_DIR/cron-watchdog.sh" 2>&1)
EXIT_CODE=$?

if echo "$RESULT" | grep -q "^ALL_OK:"; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') OK" >> "$LOG_FILE"
else
  echo "$(date '+%Y-%m-%d %H:%M:%S') PROBLEMS FOUND:" >> "$LOG_FILE"
  echo "$RESULT" >> "$LOG_FILE"
  send_telegram "$RESULT"
  echo "$(date '+%Y-%m-%d %H:%M:%S') Telegram alert sent" >> "$LOG_FILE"
fi

# Keep log under 1MB
if [ -f "$LOG_FILE" ] && [ "$(wc -c < "$LOG_FILE")" -gt 1048576 ]; then
  tail -100 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
fi
