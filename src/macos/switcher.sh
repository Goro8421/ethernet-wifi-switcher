#!/bin/bash
set -euo pipefail

NETWORKSETUP="/usr/sbin/networksetup"
ROUTE="/sbin/route"
PING="/sbin/ping"
DATE="/bin/date"

# These will be set by the installer
WIFI_DEV="${WIFI_DEV:-en0}"
ETH_DEV="${ETH_DEV:-en5}"
STATE_DIR="${STATE_DIR:-/tmp}"

FAILCOUNT_FILE="${STATE_DIR}/eth_failcount"
LAST_ETH_STATE_FILE="${STATE_DIR}/last_eth_state"   # ok|fail|unknown
MAX_FAILS_BEFORE_WIFI_ON=2

mkdir -p "$STATE_DIR" >/dev/null 2>&1 || true

now(){ "$DATE" "+%Y-%m-%d %H:%M:%S"; }
log(){ echo "[$(now)] $*"; }

default_iface(){ "$ROUTE" -n get default 2>/dev/null | awk '/interface:/{print $2; exit}'; }
default_gateway(){ "$ROUTE" -n get default 2>/dev/null | awk '/gateway:/{print $2; exit}'; }

wifi_state(){
  "$NETWORKSETUP" -getairportpower "$WIFI_DEV" 2>/dev/null | awk '{print $NF}' | tr '[:upper:]' '[:lower:]' || echo "unknown"
}

set_wifi(){
  local desired="$1" cur
  cur="$(wifi_state)"
  [[ "$cur" == "$desired" ]] && return 0
  "$NETWORKSETUP" -setairportpower "$WIFI_DEV" "$desired"
  log "wifi-change: $cur -> $desired (iface=$(default_iface || echo '?') gw=$(default_gateway || echo '?'))"
}

read_failcount(){
  if [[ -f "$FAILCOUNT_FILE" ]]; then
    cat "$FAILCOUNT_FILE" 2>/dev/null || echo "0"
  else
    echo "0"
  fi
}

write_failcount(){ echo "$1" > "$FAILCOUNT_FILE"; }

read_last_eth_state(){
  if [[ -f "$LAST_ETH_STATE_FILE" ]]; then
    cat "$LAST_ETH_STATE_FILE" 2>/dev/null || echo "unknown"
  else
    echo "unknown"
  fi
}

write_last_eth_state(){ echo "$1" > "$LAST_ETH_STATE_FILE"; }

check_eth(){
  local gw
  gw="$(default_gateway)"
  if [[ -z "$gw" ]]; then
    return 1
  fi
  
  # Ping gateway to ensure it's actually reachable
  if "$PING" -t 1 -c 1 "$gw" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

main(){
  local eth_ok=0
  if check_eth; then
    eth_ok=1
  fi

  local last_state
  last_state="$(read_last_eth_state)"
  local failcount
  failcount="$(read_failcount)"

  if (( eth_ok )); then
    # Ethernet is UP
    write_failcount 0
    write_last_eth_state "ok"
    set_wifi "off"
  else
    # Ethernet is DOWN
    write_last_eth_state "fail"
    failcount=$(( failcount + 1 ))
    write_failcount "$failcount"
    
    if (( failcount >= MAX_FAILS_BEFORE_WIFI_ON )); then
      set_wifi "on"
    fi
  fi
}

main "$@"
