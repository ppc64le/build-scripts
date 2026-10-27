#!/usr/bin/env bash
# setup-queues.sh — Resolve POWERCORE_RUNTIME from systemd.env and ensure all
# queue directories exist. Writes POWERCORE_RUNTIME to $GITHUB_ENV.
#
# Usage:
#   setup-queues.sh
#
# Requires: 'powercore' system user to exist (run after install-powercore.sh).
set -euo pipefail

if ! id powercore &>/dev/null; then
  echo "ERROR: 'powercore' user does not exist — run install-powercore.sh first"
  exit 1
fi

PC_HOME=$(getent passwd powercore | cut -d: -f6)

# ── Resolve POWERCORE_RUNTIME from systemd.env ──────────────────────────────
# powercore-install runs deploy-workflow.sh which writes systemd.env at the
# actual runtime path.  The default fallback in deploy-workflow.sh (line 34):
#   $POWERCORE_RUNTIME > $BULKSEARCH_RUNTIME > $HOME/bulksearch/runtime
# We search the most common candidate paths first, then fall back to find.
SYSTEMD_ENV=""
for candidate in \
  "${PC_HOME}/powercore/runtime/config/systemd.env" \
  "${PC_HOME}/bulksearch/runtime/config/systemd.env" \
  "${PC_HOME}/.local/share/powercore/runtime/config/systemd.env"; do
  if sudo -u powercore test -f "${candidate}" 2>/dev/null; then
    SYSTEMD_ENV="${candidate}"
    break
  fi
done

if [ -z "${SYSTEMD_ENV}" ]; then
  SYSTEMD_ENV=$(sudo -u powercore find "${PC_HOME}" \
    -maxdepth 6 -name "systemd.env" -path "*/runtime/config/systemd.env" \
    2>/dev/null | head -1)
fi

if [ -n "${SYSTEMD_ENV}" ]; then
  POWERCORE_RUNTIME=$(sudo -u powercore grep -m1 '^POWERCORE_RUNTIME=' "${SYSTEMD_ENV}" \
    | cut -d= -f2- | tr -d ' "' || true)
else
  echo "WARN: systemd.env not found under ${PC_HOME}; using the default runtime path"
fi

# Fallback to default derived from POWERCORE_WORKSPACE
if [ -z "${POWERCORE_RUNTIME:-}" ]; then
  POWERCORE_RUNTIME="${PC_HOME}/powercore/runtime"
fi

echo "--- Preparing queues: ${POWERCORE_RUNTIME} ---"

# Export for all downstream steps in this GHA job
echo "POWERCORE_RUNTIME=${POWERCORE_RUNTIME}" >> "${GITHUB_ENV}"

# ── Ensure all queue directories exist ──────────────────────────────────────
# deploy-workflow.sh creates inbox/outbox/processing per stage; add any missing
# failed/ and requests/ directories required for worker error handling.
CREATED=0

_ensure_dir() {
  if ! sudo -u powercore test -d "$1" 2>/dev/null; then
    sudo -u powercore mkdir -p "$1"
    echo "  CREATED: ${1#${POWERCORE_RUNTIME}/}"
    CREATED=$(( CREATED + 1 ))
  fi
}

for stage in 03-preprocess 04-shallow-scan 05-deep-scan 06-post-process 07-bookkeeping; do
  for sub in inbox outbox processing failed; do
    _ensure_dir "${POWERCORE_RUNTIME}/queues/${stage}/${sub}"
  done
done
for dir in requests incoming input logs; do
  _ensure_dir "${POWERCORE_RUNTIME}/${dir}"
done

if ! sudo -u powercore test -d "${POWERCORE_RUNTIME}/queues" || \
   ! sudo -u powercore test -d "${POWERCORE_RUNTIME}/requests"; then
  echo "ERROR: queue setup verification failed under ${POWERCORE_RUNTIME}"
  sudo -u powercore find "${POWERCORE_RUNTIME}" -maxdepth 3 -type d 2>/dev/null | sort || true
  exit 1
fi

echo "PowerCore queues ready (${CREATED} directories created)"
