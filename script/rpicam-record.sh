#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="/etc/default/rpicam-record"
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

BASE_ROOT="${BASE_ROOT:-/mnt/recordings}"
CODEC="${CODEC:-h264}"
OUTPUT_EXT="${OUTPUT_EXT:-$CODEC}"
WIDTH="${WIDTH:-1280}"
HEIGHT="${HEIGHT:-720}"
FRAMERATE="${FRAMERATE:-15}"
NO_PREVIEW="${NO_PREVIEW:-1}"
MIN_START_SECONDS="${MIN_START_SECONDS:-5}"

seconds_to_next_hour() {
  local now next
  now=$(date +%s)
  next=$(( (now / 3600 + 1) * 3600 ))
  echo $(( next - now ))
}

ALIGNED=0

while true; do
  DATE_DIR="$(date +%Y%m%d)"
  BASE_DIR="${BASE_ROOT}/${DATE_DIR}"
  mkdir -p "$BASE_DIR"

  FILE="${BASE_DIR}/record_$(date +%Y%m%d_%H%M%S).${OUTPUT_EXT}"

  if [[ "$ALIGNED" -eq 0 ]]; then
    SECS=$(seconds_to_next_hour)
    if [[ "$SECS" -lt "$MIN_START_SECONDS" ]]; then
      SECS=3600
    fi
    ALIGNED=1
  else
    SECS=3600
  fi

  TIMEOUT_MS=$(( SECS * 1000 ))

  CMD=(
    rpicam-vid
    --codec "$CODEC"
    --width "$WIDTH"
    --height "$HEIGHT"
    --framerate "$FRAMERATE"
    --timeout "$TIMEOUT_MS"
    -o "$FILE"
  )

  if [[ "$NO_PREVIEW" == "1" ]]; then
    CMD+=(--nopreview)
  fi

  "${CMD[@]}"
  sleep 1
done
