#!/usr/bin/env bash
set -euo pipefail

BUILDROOT_DOWNLOADS_URL="${BUILDROOT_DOWNLOADS_URL:-https://buildroot.org/downloads/}"

latest_release="$({
  curl -fsSL "${BUILDROOT_DOWNLOADS_URL}" \
    | grep -Eo 'href="buildroot-[0-9]{4}\.[0-9]{2}(\.[0-9]+)?\.tar\.gz"' \
    | sed -E 's/^href="//; s/"$//' \
    | sed -E 's/^buildroot-//; s/\.tar\.gz$//' \
    | sort -Vu
} | tail -n1)"

if [[ -z "${latest_release}" ]]; then
  echo "Failed to determine latest stable Buildroot release from ${BUILDROOT_DOWNLOADS_URL}" >&2
  exit 1
fi

echo "${latest_release}"
