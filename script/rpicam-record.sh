#!/bin/bash
set -euo pipefail

BASE_ROOT="/mnt/recordings"

# 次の正時までの残り秒を返す
seconds_to_next_hour() {
  local now next
  now=$(date +%s)
  next=$(( (now / 3600 + 1) * 3600 ))
  echo $(( next - now ))
}

# ループ開始時点が「正時境界に揃ってるか」フラグ
ALIGNED=0

while true; do
  DATE_DIR="$(date +%Y%m%d)"
  BASE_DIR="${BASE_ROOT}/${DATE_DIR}"
  mkdir -p "$BASE_DIR"

  FILE="${BASE_DIR}/record_$(date +%Y%m%d_%H%M%S).h264"

  if [[ "$ALIGNED" -eq 0 ]]; then
    # 初回：次の正時まで（短いファイルになる可能性あり。ここで帳尻合わせ）
    SECS=$(seconds_to_next_hour)
    # 念のため短すぎる場合は次の1時間へ（例：境界直前に起動）
    if [[ "$SECS" -lt 5 ]]; then
      SECS=3600
    fi
    ALIGNED=1
  else
    # 2回目以降：きっちり1時間
    SECS=3600
  fi

  TIMEOUT_MS=$(( SECS * 1000 ))

  rpicam-vid \
    --codec h264 \
    --nopreview \
    --width 1280 \
    --height 720 \
    --framerate 15 \
    --timeout "$TIMEOUT_MS" \
    -o "$FILE"

  # 連続起動の安定化
  sleep 1
done
