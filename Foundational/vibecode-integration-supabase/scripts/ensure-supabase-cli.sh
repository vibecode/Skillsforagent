#!/usr/bin/env bash
# ensure-supabase-cli.sh — on-demand install of the `supabase` CLI.
#
# Mirrors the trust model used by the Vibecode iOS pipeline
# (apps/signing-service/cli/src/supabase-binary.ts in vibecode/chorus):
#   - pinned version + per-platform SHA-256
#   - download from the official GitHub release, verify, then install
#   - cache under ~/.vibecode/bin so later runs are instant
#
# Resolution order:
#   1. `supabase` already on PATH (brew/apt/scoop installs).
#   2. ~/.vibecode/bin/supabase from a previous run.
#   3. Download + SHA-256 verify + extract + install at #2.
#
# Prints the resolved binary path to stdout. All logs go to stderr so callers
# can do:  SUPABASE_BIN="$(ensure-supabase-cli.sh)"
#
# Bump SUPABASE_CLI_VERSION + the PINNED_SHA256 table together when upgrading.
set -euo pipefail

SUPABASE_CLI_VERSION="2.98.2"

# SHA-256 of each release tarball (GitHub release asset `digest` field, v2.98.2).
pinned_sha256() {
  case "$1" in
    supabase_darwin_arm64.tar.gz)  echo "d29d34b2cc1299b98ae03202309962b692993e2b1934d45870912b26af89f03d" ;;
    supabase_darwin_amd64.tar.gz)  echo "d11af509b945510ba01cb33d151b5749a687bfbaacb64a1a0d832c9cd1f12d30" ;;
    supabase_linux_amd64.tar.gz)   echo "0f59df9e6837e876f309e0b4f47005133c51296e85a02727b2927f33ed9adb2d" ;;
    supabase_linux_arm64.tar.gz)   echo "d82f8533301cf24111c4a04d146cdb9c06a0496ed64c5a2f52f00a3cc55cbef7" ;;
    supabase_windows_amd64.tar.gz) echo "b2c923bcceed8451d4c332545dba15e87dbf4e2505d200cd3a8e25583ef2751d" ;;
    supabase_windows_arm64.tar.gz) echo "7b38c24d00109611fe09c1f4bc67679544566ad89f13dd88cd1987c54f6fb06d" ;;
    *) return 1 ;;
  esac
}

log() { printf '[supabase-install] %s\n' "$*" >&2; }

BIN_DIR="${HOME}/.vibecode/bin"
MANAGED_BIN="${BIN_DIR}/supabase"

probe() { "$1" --version >/dev/null 2>&1; }

# 1. PATH lookup.
if command -v supabase >/dev/null 2>&1 && probe supabase; then
  command -v supabase
  exit 0
fi

# 2. Vibecode-managed copy.
if [ -x "${MANAGED_BIN}" ] && probe "${MANAGED_BIN}"; then
  echo "${MANAGED_BIN}"
  exit 0
fi

# 3. Download + verify + install.
detect_archive() {
  local os cpu
  os="$(uname -s)"; cpu="$(uname -m)"
  case "${os}-${cpu}" in
    Darwin-arm64)            echo "supabase_darwin_arm64.tar.gz" ;;
    Darwin-x86_64)           echo "supabase_darwin_amd64.tar.gz" ;;
    Linux-x86_64)            echo "supabase_linux_amd64.tar.gz" ;;
    Linux-aarch64|Linux-arm64) echo "supabase_linux_arm64.tar.gz" ;;
    *) log "unsupported platform ${os}/${cpu}; install supabase manually and re-run"; return 1 ;;
  esac
}

ARCHIVE="$(detect_archive)"
EXPECTED_SHA="$(pinned_sha256 "${ARCHIVE}")" || { log "no pinned SHA for ${ARCHIVE}"; exit 1; }

mkdir -p "${BIN_DIR}"

# Lockfile guard so concurrent first-runs don't corrupt each other.
LOCK="${BIN_DIR}/.supabase-install.lock"
acquire_lock() {
  local deadline=$(( $(date +%s) + 120 ))
  while ! ( set -o noclobber; : > "${LOCK}" ) 2>/dev/null; do
    # Steal a stale lock (>5 min old).
    if [ -f "${LOCK}" ]; then
      local age; age=$(( $(date +%s) - $(stat -c %Y "${LOCK}" 2>/dev/null || stat -f %m "${LOCK}" 2>/dev/null || echo 0) ))
      [ "${age}" -gt 300 ] && rm -f "${LOCK}"
    fi
    [ "$(date +%s)" -ge "${deadline}" ] && { log "timed out waiting for install lock"; exit 1; }
    sleep 0.25
  done
}
acquire_lock
trap 'rm -f "${LOCK}"' EXIT

# Re-check: another process may have finished while we waited.
if [ -x "${MANAGED_BIN}" ] && probe "${MANAGED_BIN}"; then
  echo "${MANAGED_BIN}"
  exit 0
fi

STAGING="${BIN_DIR}/.staging-$$"
mkdir -p "${STAGING}"
trap 'rm -rf "${STAGING}"; rm -f "${LOCK}"' EXIT

URL="https://github.com/supabase/cli/releases/download/v${SUPABASE_CLI_VERSION}/${ARCHIVE}"
log "downloading ${URL}"
curl -fsSL --max-time 120 -o "${STAGING}/${ARCHIVE}" "${URL}"

# Verify SHA-256 (sha256sum on Linux, shasum on macOS).
if command -v sha256sum >/dev/null 2>&1; then
  ACTUAL_SHA="$(sha256sum "${STAGING}/${ARCHIVE}" | awk '{print $1}')"
else
  ACTUAL_SHA="$(shasum -a 256 "${STAGING}/${ARCHIVE}" | awk '{print $1}')"
fi
if [ "${ACTUAL_SHA}" != "${EXPECTED_SHA}" ]; then
  log "SHA-256 mismatch for ${ARCHIVE}: expected ${EXPECTED_SHA}, got ${ACTUAL_SHA}. Refusing to install."
  exit 1
fi
log "verified SHA-256"

tar -xzf "${STAGING}/${ARCHIVE}" -C "${STAGING}"
[ -f "${STAGING}/supabase" ] || { log "archive did not contain supabase binary"; exit 1; }
chmod 0755 "${STAGING}/supabase"
mv -f "${STAGING}/supabase" "${MANAGED_BIN}"
chmod 0755 "${MANAGED_BIN}"

probe "${MANAGED_BIN}" || { log "installed binary failed --version probe"; exit 1; }
log "installed at ${MANAGED_BIN} (v${SUPABASE_CLI_VERSION})"
echo "${MANAGED_BIN}"
