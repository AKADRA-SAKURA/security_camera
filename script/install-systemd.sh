#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run with sudo: sudo ./script/install-systemd.sh"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

DEFAULT_USER="${SUDO_USER:-pi}"
read -r -p "Service user [${DEFAULT_USER}]: " RUN_AS_USER
RUN_AS_USER="${RUN_AS_USER:-$DEFAULT_USER}"

read -r -p "Recording root [/mnt/recordings]: " BASE_ROOT
BASE_ROOT="${BASE_ROOT:-/mnt/recordings}"

read -r -p "Width [1280]: " WIDTH
WIDTH="${WIDTH:-1280}"

read -r -p "Height [720]: " HEIGHT
HEIGHT="${HEIGHT:-720}"

read -r -p "Framerate [15]: " FRAMERATE
FRAMERATE="${FRAMERATE:-15}"

read -r -p "Codec [h264]: " CODEC
CODEC="${CODEC:-h264}"

read -r -p "Output extension [${CODEC}]: " OUTPUT_EXT
OUTPUT_EXT="${OUTPUT_EXT:-$CODEC}"

read -r -p "Disable preview (1/0) [1]: " NO_PREVIEW
NO_PREVIEW="${NO_PREVIEW:-1}"

read -r -p "Boundary guard seconds [5]: " MIN_START_SECONDS
MIN_START_SECONDS="${MIN_START_SECONDS:-5}"

install -m 755 "${REPO_ROOT}/script/rpicam-record.sh" /usr/local/bin/rpicam-record.sh

TMP_SERVICE="$(mktemp)"
sed "s/__RUN_AS_USER__/${RUN_AS_USER}/g" "${REPO_ROOT}/service/rpicam-record.service" > "${TMP_SERVICE}"
install -m 644 "${TMP_SERVICE}" /etc/systemd/system/rpicam-record.service
rm -f "${TMP_SERVICE}"

cat > /etc/default/rpicam-record <<EOF
BASE_ROOT=${BASE_ROOT}
CODEC=${CODEC}
OUTPUT_EXT=${OUTPUT_EXT}
WIDTH=${WIDTH}
HEIGHT=${HEIGHT}
FRAMERATE=${FRAMERATE}
NO_PREVIEW=${NO_PREVIEW}
MIN_START_SECONDS=${MIN_START_SECONDS}
EOF

systemctl daemon-reload
systemctl enable --now rpicam-record.service

if ! id -nG "${RUN_AS_USER}" | tr ' ' '\n' | grep -qx video; then
  echo "warning: user '${RUN_AS_USER}' is not in the video group."
  echo "run: sudo usermod -aG video ${RUN_AS_USER}"
fi

echo
echo "Installed and started: rpicam-record.service"
echo "Check status: sudo systemctl status rpicam-record.service --no-pager"