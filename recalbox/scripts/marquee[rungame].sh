#!/bin/bash

ESP_IP="192.168.1.108"
STATEFILE="/tmp/es_state.inf"

# Parse les args nommés selon la doc Recalbox actuelle
PARAM=""
while [ $# -gt 0 ]; do
  case "$1" in
    -param)     PARAM="$2"; shift 2 ;;
    -statefile) STATEFILE="$2"; shift 2 ;;
    -action)    shift 2 ;;
    *)          shift ;;
  esac
done

# Le path ROM est dans -param OU dans ActionData du state file (fallback)
ROM_PATH="$PARAM"
if [ -z "$ROM_PATH" ] && [ -f "$STATEFILE" ]; then
  ROM_PATH=$(grep '^ActionData=' "$STATEFILE" | cut -d= -f2- | tr -d '\r')
fi

if [ -z "$ROM_PATH" ]; then
  exit 0
fi

PATHONLY=$(dirname "$ROM_PATH")
SYSTEM=$(basename "$PATHONLY")
GAMENAME=$(basename "$ROM_PATH")
GAMENAME="${GAMENAME%.*}"

# Titre du jeu depuis le state file (fallback sur GAMENAME)
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

