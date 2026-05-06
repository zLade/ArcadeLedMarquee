#!/bin/bash

ESP_IP="192.168.1.108"
STATEFILE="/tmp/es_state.inf"
LASTSYS_FILE="/tmp/marquee_lastsys"
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

# Workaround bug filtre Recalbox
case "$ACTION" in
  systembrowsing) ;;
  *) exit 0 ;;
esac

# SystemId court via -param ou SystemId du state file
SYSTEM="$PARAM"
if [ -z "$SYSTEM" ] && [ -f "$STATEFILE" ]; then
  SYSTEM=$(grep '^SystemId=' "$STATEFILE" | cut -d= -f2- | tr -d '\r')
fi
[ -z "$SYSTEM" ] && exit 0

# Anti-flicker: skip if same system than before
LASTSYS=""
[ -f "$LASTSYS_FILE" ] && LASTSYS=$(cat "$LASTSYS_FILE" 2>/dev/null)
[ "$SYSTEM" = "$LASTSYS" ] && exit 0
echo "$SYSTEM" > "$LASTSYS_FILE"

# Reset tracking jeu: quand on change de système, le prochain jeu sélectionné
# doit déclencher un nouveau marquee même si c'est le même nom
rm -f "$LASTGAME_FILE"

# Nom complet du système pour fallback scroll
SYSTEMNAME=$(grep '^System=' "$STATEFILE" 2>/dev/null | cut -d= -f2- | tr -d '\r')
[ -z "$SYSTEMNAME" ] && SYSTEMNAME="$SYSTEM"

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

URLENCODED_SYSTEMNAME=$(rawurlencode "$SYSTEMNAME")
curl -s "http://${ESP_IP}/gif?s=${SYSTEM}&g=default&t=${URLENCODED_SYSTEMNAME}" >/dev/null 2>&1 &
