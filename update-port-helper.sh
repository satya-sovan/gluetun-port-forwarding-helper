#!/bin/sh
set -eu

GLUETUN_URL="${GLUETUN_URL:-http://gluetun:8000/v1/openvpn/portforwarded}"
QBIT_URL="${QBIT_URL:-http://qbittorrent:8080}"
QBIT_USER="${QBIT_USER:-admin}"
QBIT_PASS="${QBIT_PASS:-adminadmin}"
COOKIE_FILE="/tmp/qb_cookie.txt"
TMP_JSON="/tmp/qbit_prefs.json"
INTERVAL_SECONDS=${INTERVAL_SECONDS:-900}

log() { echo "$(date -Is) - $*"; }

get_forwarded_port() {
  resp=$(curl -sS --max-time 10 "$GLUETUN_URL" || echo "")
  if [ -z "$resp" ]; then
    log "Failed to query Gluetun at $GLUETUN_URL"
    echo "0"
    return
  fi
  echo "$resp" | jq -r '.port // 0'
}

get_qbit_listen_port() {
  if ! curl -sS --cookie "$COOKIE_FILE" "$QBIT_URL/api/v2/app/preferences" -o "$TMP_JSON" 2>/dev/null; then
    echo ""
    return
  fi
  jq -r '.listen_port // empty' "$TMP_JSON" || echo ""
}

qbit_login() {
  rm -f "$COOKIE_FILE"
  if curl -sS -c "$COOKIE_FILE" -d "username=$QBIT_USER&password=$QBIT_PASS" "$QBIT_URL/api/v2/auth/login" | grep -q "Ok"; then
    return 0
  fi
  if [ -s "$COOKIE_FILE" ]; then
    return 0
  fi
  return 1
}

qbit_set_port() {
  newport="$1"
  payload=$(jq -n --arg p "$newport" '{"listen_port": ($p|tonumber)}')
  if curl -sS -b "$COOKIE_FILE" -d "json=$payload" "$QBIT_URL/api/v2/app/setPreferences" >/dev/null; then
    log "Updated qBittorrent listen_port => $newport"
    return 0
  else
    log "Failed to set qBittorrent port to $newport"
    return 1
  fi
}

run_once() {
  forwarded_port=$(get_forwarded_port)
  if [ -z "$forwarded_port" ] || [ "$forwarded_port" = "0" ]; then
    log "No forwarded port returned by Gluetun (port=$forwarded_port). Will retry later."
    return 0
  fi

  if ! curl -sS --cookie "$COOKIE_FILE" "$QBIT_URL/api/v2/app/preferences" >/dev/null 2>&1; then
    log "Not logged in to qBittorrent, attempting login..."
    if ! qbit_login; then
      log "qBittorrent login failed; check credentials and API availability."
      return 1
    fi
  fi

  current_port=$(get_qbit_listen_port)
  if [ -z "$current_port" ]; then
    log "Unable to determine current qBittorrent listen_port; attempting login and retry."
    if qbit_login; then
      current_port=$(get_qbit_listen_port)
    fi
  fi

  if [ "$current_port" = "$forwarded_port" ]; then
    log "No change: qBittorrent port is already $current_port"
    return 0
  fi

  log "Port change detected: qBittorrent=$current_port -> forwarded=$forwarded_port"
  if ! qbit_set_port "$forwarded_port"; then
    log "Setting port failed. You may need to check qBittorrent Web API and credentials."
    return 1
  fi
  return 0
}

# run once immediately, then loop
while true; do
  run_once || log "update script returned non-zero"
  sleep "$INTERVAL_SECONDS"
done
