#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : z3
# Version       : z3-4.15.4
# Source repo   : https://github.com/Z3Prover/z3
# Tested on     : UBI 10 (ppc64le)
# Language      : C++, Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Daniel Schenker <daniel.schenker@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#
# Clones the Z3 theorem prover, patches it for ppc64le, builds from source,
# and produces a Python wheel.
#
# Designed to run inside a bare UBI 10 container. All required system packages
# are installed via dnf at the start of the script.
#
# Output wheel:
#   <output-dir>/z3_solver-4.15.4.0-cpXY-cpXY-linux_ppc64le.whl
#
# Usage:
#   ./build-z3-rocm-ppc64le.sh [--version z3-4.15.4] [--workdir $HOME]
#                               [--output-dir $HOME/vllm-wheels]
#
set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"

# ─── Defaults ─────────────────────────────────────────────────────────────────
Z3_VERSION="z3-4.15.4"
WORK_DIR="${HOME}"
OUTPUT_DIR=""          # resolved to ${WORK_DIR}/vllm-wheels after arg parsing

# ─── Helpers ──────────────────────────────────────────────────────────────────
die()  { echo "ERROR: $*" >&2; exit 1; }
info() { echo "==> $*"; }

usage() {
    cat <<EOF
Usage:
  $SCRIPT_NAME [options]

Options:
  --version VERSION     Z3 git tag to build (default: $Z3_VERSION)
  --workdir DIR         Parent directory for the z3/ clone (default: $WORK_DIR)
  --output-dir DIR      Directory to copy the built wheel into (default: <workdir>/vllm-wheels)
  -h, --help            Show this help and exit
EOF
}

# ─── Argument parsing ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)     Z3_VERSION="$2";   shift 2 ;;
        --workdir)     WORK_DIR="$2";      shift 2 ;;
        --output-dir)  OUTPUT_DIR="$2";    shift 2 ;;
        -h|--help)     usage; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

# Resolve OUTPUT_DIR now that WORK_DIR is final
OUTPUT_DIR="${OUTPUT_DIR:-${WORK_DIR}/vllm-wheels}"

# ─── System packages ──────────────────────────────────────────────────────────
info "Installing system dependencies"
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm
dnf install -y \
    git              \
    gcc-toolset-15   \
    python3.13       \
    python3.13-devel

# ─── GCC Toolset 15 ───────────────────────────────────────────────────────────
info "Configuring GCC Toolset 15"
GCC_TOOLSET_BIN="/opt/rh/gcc-toolset-15/root/usr/bin"
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    # shellcheck disable=SC1091
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d "$GCC_TOOLSET_BIN" ]]; then
    export PATH="$GCC_TOOLSET_BIN:$PATH"
else
    die "/opt/rh/gcc-toolset-15 not found — install gcc-toolset-15"
fi
echo "Using gcc: $(command -v gcc)  ($(gcc -dumpfullversion -dumpversion))"
echo "Using ar:  $(command -v ar)"

# ─── Venv ─────────────────────────────────────────────────────────────────────
VENV_DIR="${WORK_DIR}/z3-build-env"
[[ -d "$VENV_DIR" ]] || python3.13 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"
pip install --upgrade pip setuptools wheel build

# ─── Clone ────────────────────────────────────────────────────────────────────
Z3_DIR="${WORK_DIR}/z3"
if [[ ! -d "$Z3_DIR" ]]; then
    git clone https://github.com/Z3Prover/z3.git "$Z3_DIR"
else
    info "z3 directory already exists — skipping clone"
fi
cd "$Z3_DIR"
git checkout "$Z3_VERSION"

# ─── Patch setup.py (ppc64le wheel tag) ───────────────────────────────────────
info "Patching src/api/python/setup.py (ppc64le wheel tag)"
python3 - <<'PYEOF'
from pathlib import Path
p = Path("src/api/python/setup.py")
src = p.read_text()
entry = "    ('linux', 'ppc64le'): 'manylinux2014_ppc64le',\n"
if entry in src:
    print("  setup.py already patched — skipping")
elif "TAGS = {" in src:
    p.write_text(src.replace("TAGS = {", "TAGS = {\n" + entry, 1))
    print("  setup.py patched OK")
else:
    raise SystemExit("Could not find TAGS dict in setup.py")
PYEOF

# ─── Build ────────────────────────────────────────────────────────────────────
python scripts/mk_make.py --prefix="$VIRTUAL_ENV"
cd build
make -j"$(nproc)"
make install

# ─── Wheel ────────────────────────────────────────────────────────────────────
cd "$Z3_DIR/src/api/python"
python setup.py bdist_wheel

mkdir -p "$OUTPUT_DIR"
cp dist/*.whl "$OUTPUT_DIR/"
info "Z3 wheel: $(ls "$OUTPUT_DIR"/z3*.whl)"
