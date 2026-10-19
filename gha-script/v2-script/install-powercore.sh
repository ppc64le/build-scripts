#!/usr/bin/env bash
# install-powercore.sh — Install powercore_installer wheel then run powercore-install.
#
# Usage:
#   install-powercore.sh <path-to-powercore-config.env>
#
# Expects powercore-wheels/ to already exist in CWD (populated by download-wheels.sh).
set -euo pipefail

CONFIG_ENV="${1:?config env path required}"

echo "--- Python / pip info ---"
python3 --version || python3.12 --version || true
which python3 python3.12 2>/dev/null || true

# ── pip upgrade ──────────────────────────────────────────────────────────────
# Use whatever python3 is available; fall back from 3.12 to 3 if needed.
PY_CMD=$(command -v python3.12 || command -v python3 || true)
if [ -z "${PY_CMD}" ]; then
  echo "ERROR: No python3 found on PATH"
  exit 1
fi
echo "--- Using Python: ${PY_CMD} ($( ${PY_CMD} --version)) ---"
echo "--- Upgrading pip ---"
"${PY_CMD}" -m pip install --upgrade pip --user --quiet

echo "--- Installing powercore_installer wheel ---"
installer_wheel=$(ls powercore-wheels/powercore_installer-*.whl 2>/dev/null | head -1)
if [[ -z "$installer_wheel" ]]; then
  echo "ERROR: powercore_installer wheel not found in powercore-wheels/"
  ls powercore-wheels/ || true
  exit 1
fi
echo "  Installing from: ${installer_wheel}"
sudo "${PY_CMD}" -m pip install "$installer_wheel" --force-reinstall

echo "--- Installed powercore packages ---"
"${PY_CMD}" -m pip list | grep -i powercore || true

echo "--- Running powercore-install ---"
echo "  Config: ${CONFIG_ENV}"
echo "--- powercore-config.env (safe view — keys only) ---"
grep -E '^[A-Z_]+=\S' "${CONFIG_ENV}" | sed 's/=.*/=<hidden>/' || true
sudo powercore-install --config "${CONFIG_ENV}" --non-interactive

echo "--- Verifying powercore system user ---"
if ! id powercore &>/dev/null; then
  echo "ERROR: 'powercore' system user was not created by powercore-install"
  exit 1
fi
echo "powercore user: $(id powercore)"

PC_HOME=$(getent passwd powercore | cut -d: -f6)
echo "powercore HOME: ${PC_HOME}"
ls -la "${PC_HOME}" || echo "WARN: could not list powercore HOME"

echo "--- Powercore packages (root pip) ---"
sudo "${PY_CMD}" -m pip list 2>/dev/null | grep -i powercore \
  || echo "WARN: no powercore packages under root pip"

echo "--- Powercore packages (powercore user pip) ---"
sudo -u powercore "${PY_CMD}" -m pip list 2>/dev/null | grep -i powercore \
  || echo "WARN: no powercore packages under powercore user pip"

echo "--- Locating powercore-worker binary ---"
for bin_path in /usr/local/bin/powercore-worker /usr/bin/powercore-worker \
                "${PC_HOME}/.local/bin/powercore-worker"; do
  [ -x "$bin_path" ] && echo "  Found: ${bin_path}" || echo "  Not found: ${bin_path}"
done

echo "--- Installed systemd unit files ---"
find "${PC_HOME}/.config/systemd/user/" -name "*.service" -o -name "*.target" \
  2>/dev/null | sort || echo "WARN: no unit files found"

echo "--- Installed runtime directory tree (depth 4) ---"
sudo -u powercore find "${PC_HOME}" -maxdepth 5 -type d 2>/dev/null | sort | head -50 \
  || echo "WARN: could not list powercore home tree"

echo "--- Looking for systemd.env ---"
sudo -u powercore find "${PC_HOME}" \
  -maxdepth 6 -name "systemd.env" 2>/dev/null | head -5 \
  || echo "WARN: systemd.env not found"

echo "--- systemd.env contents (sensitive values redacted) ---"
_senv=$(sudo -u powercore find "${PC_HOME}" \
  -maxdepth 6 -name "systemd.env" -path "*/runtime/config/systemd.env" \
  2>/dev/null | head -1 || true)
if [ -n "${_senv}" ]; then
  echo "  Path: ${_senv}"
  sudo -u powercore awk '
    /^[A-Z_][A-Z0-9_]*=/ {
      key = substr($0, 1, index($0, "=") - 1)
      value = substr($0, index($0, "=") + 1)
      if (key ~ /(API_KEY|PASSWORD|SECRET|TOKEN)/) value = "<redacted>"
      print key "=" value
    }
  ' "${_senv}" | head -30 || true
else
  echo "  systemd.env not present yet — may be written by deploy-workflow.sh"
fi
