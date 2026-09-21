#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mapfile -t files < <(
  cd "${repo_root}"
  {
    find buildroot-external/configs -type f 2>/dev/null || true
    find buildroot-external/package -type f 2>/dev/null || true
    [[ -f buildroot-external/Config.in ]] && echo buildroot-external/Config.in
    [[ -f buildroot-external/external.desc ]] && echo buildroot-external/external.desc
    [[ -f buildroot-external/external.mk ]] && echo buildroot-external/external.mk
    [[ -f Dockerfile.network ]] && echo Dockerfile.network
    [[ -f Dockerfile ]] && echo Dockerfile
  } | LC_ALL=C sort -u
)

if [[ ${#files[@]} -eq 0 ]]; then
  echo "none"
  exit 0
fi

revision="$({
  cd "${repo_root}"
  for file in "${files[@]}"; do
    printf '%s\0' "${file}"
    sha256sum "${file}"
  done
} | sha256sum | awk '{print substr($1, 1, 12)}')"

echo "${revision}"
