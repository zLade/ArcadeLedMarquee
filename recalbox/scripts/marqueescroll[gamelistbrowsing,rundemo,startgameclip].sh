#!/bin/bash

ESP_IP="192.168.1.108"
STATEFILE="/tmp/es_state.inf"
LASTGAME_FILE="/tmp/marquee_lastgame"

ACTION=""
PARAM=""
while [ $# -gt 0 ]; do
  case "$1" in
    -action)    ACTION="$2"; shift 2 ;;
    -param)     PARAM="$2"; shift 2 ;;
    -statefile) STATEFILE="$2"; shift 2 ;;
    *)          shift ;;
  esac
done

# Workaround bug filtre Recalbox: on filtre côté script aussi
case "$ACTION" in
  gamelistbrowsing|rundemo|startgameclip) ;;
  *) exit 0 ;;
esac

# Path ROM via -param ou ActionData (fallback)
ROM_PATH="$PARAM"
if [ -z "$ROM_PATH" ] && [ -f "$STATEFILE" ]; then
  ROM_PATH=$(grep '^ActionData=' "$STATEFILE" | cut -d= -f2- | tr -d '\r')
fi
[ -z "$ROM_PATH" ] && exit 0

# Système = premier segment après /roms/ (gère les sous-dossiers genre pcenginecd/Bonk/...)
if [[ "$ROM_PATH" == *"/roms/"* ]]; then
  AFTER="${ROM_PATH#*/roms/}"
  SYSTEM="${AFTER%%/*}"
else
  SYSTEM="$(basename "$(dirname "$ROM_PATH")")"
fi

# Nom du jeu (gestion .cue pour les CD)
GAMENAME="$(basename "$ROM_PATH")"
[ -f "$ROM_PATH" ] && GAMENAME="${GAMENAME%.*}"
[[ "$ROM_PATH" == *.cue ]] && GAMENAME="$(basename "$(dirname "$ROM_PATH")")"

# Anti-flicker: skip si même jeu que la dernière fois
LASTGAME=""
[ -f "$LASTGAME_FILE" ] && LASTGAME=$(cat "$LASTGAME_FILE" 2>/dev/null)
[ "$GAMENAME" = "$LASTGAME" ] && exit 0
echo "$GAMENAME" > "$LASTGAME_FILE"
# reset tracking system
rm -f /tmp/marquee_lastsys

# Titre depuis state file
GAMETITLE=$(grep '^Game=' "$STATEFILE" 2>/dev/null | cut -d= -f2- | tr -d '\r')
[ -z "$GAMETITLE" ] && GAMETITLE="$GAMENAME"

rawurlencode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o
  for (( pos=0 ; pos<strlen ; pos++ )); do
    c=${string:$pos:1}
    case "$c" in
      [-_.~a-zA-Z0-9] ) o="${c}" ;;
      * )               printf -v o '%%%02x' "'$c"
    esac
    encoded+="${o}"
  done
  echo "${encoded}"
}

if [ -n "$SYSTEM" ] && [ -n "$GAMENAME" ]; then
  URLENCODED_GAMENAME=$(rawurlencode "$GAMENAME")
  URLENCODED_TITLE=$(rawurlencode "$GAMETITLE")
  curl -s "http://${ESP_IP}/gif?s=${SYSTEM}&g=${URLENCODED_GAMENAME}&t=${URLENCODED_TITLE}" >/dev/null 2>&1 &
fi
