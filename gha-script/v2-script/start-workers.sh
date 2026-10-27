#!/usr/bin/env bash
# start-workers.sh — Start powercore-workflow.target via systemd user session and
# verify all 5 stage workers reach 'active' state.
#
# Usage:
#   start-workers.sh
#
# Requires: 'powercore' system user to exist (run after install-powercore.sh).
set -euo pipefail

if ! id powercore &>/dev/null; then
  echo "ERROR: 'powercore' user does not exist"
  exit 1
fi

POWERCORE_UID=$(id -u powercore)
XDG_DIR="/run/user/${POWERCORE_UID}"
DBUS="unix:path=/run/user/${POWERCORE_UID}/bus"
PC_HOME=$(getent passwd powercore | cut -d: -f6)

# Sensitive information redacted for security
echo "--- Initializing powercore worker startup ---"

# ── Resolve POWERCORE_RUNTIME from installed systemd.env ─────────────────────
SYSTEMD_ENV=""
for candidate in \
  "${PC_HOME}/powercore/runtime/config/systemd.env" \
  "${PC_HOME}/bulksearch/runtime/config/systemd.env" \
  "${PC_HOME}/.local/share/powercore/runtime/config/systemd.env"; do
  if sudo -u powercore test -f "${candidate}" 2>/dev/null; then
    SYSTEMD_ENV="${candidate}"
    echo "--- Found systemd.env configuration ---"
    break
  fi
done

if [ -z "${SYSTEMD_ENV}" ]; then
  echo "--- Searching for systemd.env under ${PC_HOME} ---"
  SYSTEMD_ENV=$(sudo -u powercore find "${PC_HOME}" \
    -maxdepth 6 -name "systemd.env" -path "*/runtime/config/systemd.env" \
    2>/dev/null | head -1)
  [ -n "${SYSTEMD_ENV}" ] && echo "--- Found systemd.env via filesystem search ---"
fi

if [ -z "${SYSTEMD_ENV}" ]; then
  echo "ERROR: systemd.env not found under ${PC_HOME} — has powercore-install completed?"
  echo "--- Directory tree under ${PC_HOME} (depth 5) ---"
  sudo -u powercore find "${PC_HOME}" -maxdepth 5 -type d 2>/dev/null | sort | head -40 || true
  exit 1
fi

# Print the worker environment with secret values redacted.
echo "--- PowerCore worker environment (values redacted for sensitive variables) ---"
sudo -u powercore awk '
  /^[[:space:]]*#/ || !/=/{next}
  {
    key = $0
    sub(/[[:space:]]*=.*/, "", key)
    value = $0
    sub(/^[^=]*=[[:space:]]*/, "", value)
    if (key ~ /(API_KEY|ACCESS_KEY|SECRET|PASSWORD|TOKEN|CREDENTIAL|PRIVATE_KEY)/) {
      value = "<redacted>"
    }
    print key "=" value
  }
' "${SYSTEMD_ENV}" || true
echo "--- End PowerCore worker environment ---"

# Read actual POWERCORE_RUNTIME from systemd.env (the canonical source)
POWERCORE_RUNTIME=$(sudo -u powercore grep -m1 '^POWERCORE_RUNTIME=' "${SYSTEMD_ENV}" \
  | cut -d= -f2- | tr -d ' "' || true)
if [ -z "${POWERCORE_RUNTIME}" ]; then
  echo "WARN: POWERCORE_RUNTIME not found in systemd.env — deriving from config dir"
  CONFIG_DIR=$(dirname "${SYSTEMD_ENV}")
  POWERCORE_RUNTIME=$(dirname "${CONFIG_DIR}")
fi
echo "--- POWERCORE_RUNTIME configured ---"

# Helper: run a systemctl command as the powercore user
_sctl() {
  sudo -u powercore \
    XDG_RUNTIME_DIR="${XDG_DIR}" \
    DBUS_SESSION_BUS_ADDRESS="${DBUS}" \
    systemctl --user "$@"
}

# ── Ensure shallow-scan always receives --force-rebuild ───────────────────────
# Pass the flag directly to the worker so it takes precedence over any
# POWERCORE_FORCE_REBUILD value loaded from environment files.
UNIT_FILE=""
for candidate in \
  "${PC_HOME}/.config/systemd/user/powercore-worker@.service" \
  "/etc/systemd/user/powercore-worker@.service" \
  "/usr/lib/systemd/user/powercore-worker@.service"; do
  if sudo -u powercore test -f "${candidate}" 2>/dev/null; then
    UNIT_FILE="${candidate}"
    break
  fi
done

if [ -z "${UNIT_FILE}" ]; then
  echo "ERROR: powercore-worker@.service not found"
  exit 1
fi

if ! sudo -u powercore grep -q -- '--force-rebuild' "${UNIT_FILE}"; then
  sudo -u powercore sed -i \
    's|^ExecStart=\(.*powercore-worker.*%i\)$|ExecStart=\1 --force-rebuild|' \
    "${UNIT_FILE}"
fi
_sctl daemon-reload

# ── Check if all workers are already active ──────────────────────────────────
echo "--- Checking current worker status ---"
ALL_ALREADY_ACTIVE=true
for stage in 03-preprocess 04-shallow-scan 05-deep-scan 06-post-process 07-bookkeeping; do
  STATUS=$(_sctl is-active "powercore-worker@${stage}.service" 2>/dev/null || echo "inactive")
  echo "  powercore-worker@${stage}: ${STATUS}"
  if [ "$STATUS" != "active" ]; then
    ALL_ALREADY_ACTIVE=false
  fi
done

# Only start/reload if services are not all active
if [ "$ALL_ALREADY_ACTIVE" = "true" ]; then
  echo "--- All PowerCore workers already active, no action needed ---"
else
  echo "--- Some workers are down, starting powercore-workflow.target ---"
  _sctl start powercore-workflow.target || true
  
  echo "--- Waiting 30s for workers to initialise ---"
  sleep 30
fi

# ── Verify all workers are active ─────────────────────────────────────────────
echo "--- Final worker status verification ---"
ALL_ACTIVE=true
for stage in 03-preprocess 04-shallow-scan 05-deep-scan 06-post-process 07-bookkeeping; do
  STATUS=$(_sctl is-active "powercore-worker@${stage}.service" 2>/dev/null || true)
  echo "  powercore-worker@${stage}: ${STATUS}"
  if [ "$STATUS" != "active" ]; then
    echo "  --- Journal for powercore-worker@${stage} ---"
    sudo -u powercore \
      XDG_RUNTIME_DIR="${XDG_DIR}" \
      DBUS_SESSION_BUS_ADDRESS="${DBUS}" \
      journalctl --user -u "powercore-worker@${stage}.service" \
        --no-pager -n 50 2>/dev/null || true
    ALL_ACTIVE=false
  fi
done

if [ "$ALL_ACTIVE" = "false" ]; then
  echo "ERROR: one or more PowerCore workers failed to reach 'active' state"
  exit 1
fi
echo "--- All PowerCore workers active ---"
