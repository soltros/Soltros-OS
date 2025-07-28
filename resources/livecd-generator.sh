#!/usr/bin/env bash

set -euo pipefail

KICKSTART="soltros-flat.ks"
LABEL="Soltros-Minimal"
CACHE_DIR="/var/cache/live"
ISO_OUTPUT_DIR="./output"

DATESTAMP=$(date +"%Y%m%d-%H%M")
OUTPUT_ISO="${ISO_OUTPUT_DIR}/${LABEL}-${DATESTAMP}.iso"

mkdir -p "${CACHE_DIR}"
mkdir -p "${ISO_OUTPUT_DIR}"

echo "Starting Soltros ISO build at ${DATESTAMP}..."
echo "Kickstart: ${KICKSTART}"
echo "Output ISO will be: ${OUTPUT_ISO}"

sudo livecd-creator \
  --verbose \
  --config="${KICKSTART}" \
  --fslabel="${LABEL}" \
  --cache="${CACHE_DIR}" \
  --title="${LABEL}" \
  --releasever=39 \
  --tmpdir=/var/tmp \
  --logfile="${ISO_OUTPUT_DIR}/build-${DATESTAMP}.log"

# Rename the resulting ISO to include timestamp
if [[ -f "${LABEL}.iso" ]]; then
  mv "${LABEL}.iso" "${OUTPUT_ISO}"
  echo "ISO successfully created: ${OUTPUT_ISO}"
else
  echo "Error: ISO was not created."
  exit 1
fi
