#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : tilelang
# Version       : 0.1.10
# Source repo   : https://github.com/tile-ai/tilelang
# Tested on     : UBI 10 (ppc64le)
# Language      : Python, C++
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
# Clones TileLang, builds it for ROCm, and produces a Python wheel.
# Requires a pre-built z3-solver wheel in --extra-wheel-dir.
#
# TileLang ships vendored HIP headers (3rdparty/hip-headers/) so the ROCm
# backend compiles without a ROCm runtime on the build host. Backend selection
# is passed to CMake via CMAKE_ARGS; no ROCM_PATH or system HIP libraries are
# required at build time.
#
# Output wheel:
#   <output-dir>/tilelang-0.1.10-cpXY-cpXY-linux_ppc64le.whl
#
# Usage:
#   ./build-tilelang-ppc64le-ubi10.sh [--version 0.1.10] [--workdir $HOME]
#                                     [--extra-wheel-dir $HOME/vllm-wheels]
#                                     [--output-dir $HOME/vllm-wheels]
#
set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"

# ─── Defaults ─────────────────────────────────────────────────────────────────
TILELANG_VERSION="0.1.10"
WORK_DIR="${HOME}"
OUTPUT_DIR=""        # resolved to ${WORK_DIR}/vllm-wheels after arg parsing

# ─── Helpers ──────────────────────────────────────────────────────────────────
die()  { echo "ERROR: $*" >&2; exit 1; }
info() { echo "==> $*"; }

usage() {
    cat <<EOF
Usage:
  $SCRIPT_NAME [options]

Options:
  --version VERSION     TileLang git tag to build (default: $TILELANG_VERSION)
  --workdir DIR         Parent directory for the tilelang/ clone (default: $WORK_DIR)
  --output-dir DIR      Directory to copy the built wheel into (default: <workdir>/vllm-wheels)
  -h, --help            Show this help and exit
EOF
}

# ─── Argument parsing ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)    TILELANG_VERSION="$2"; shift 2 ;;
        --workdir)    WORK_DIR="$2";          shift 2 ;;
        --output-dir) OUTPUT_DIR="$2";         shift 2 ;;
        -h|--help)    usage; exit 0 ;;
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
    cmake            \
    ninja-build      \
    python3.13       \
    python3.13-devel

# ─── GCC Toolset 15 ───────────────────────────────────────────────────────────
# Enable before any pip install so that subprocesses spawned by pip (e.g. for
# building numpy/cython C extensions) inherit the toolset gcc/ar/etc on PATH.
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

# ─── Venv ─────────────────────────────────────────────────────────────────────
VENV_DIR="${WORK_DIR}/tilelang-build-env"
[[ -d "$VENV_DIR" ]] || python3.13 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"
pip install --upgrade pip setuptools wheel build

IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"
pip install --trusted-host wheels.developerfirst.ibm.com --extra-index-url "${IBM_WHEELS}" z3-solver
pip install numpy tqdm cython patchelf "scikit-build-core[pyproject]" cmake ninja

# ─── Clone ────────────────────────────────────────────────────────────────────
TILELANG_DIR="${WORK_DIR}/tilelang"
if [[ ! -d "$TILELANG_DIR" ]]; then
    git clone --recursive https://github.com/tile-ai/tilelang.git "$TILELANG_DIR"
else
    info "tilelang directory already exists — skipping clone"
fi
cd "$TILELANG_DIR"

info "Checking out v${TILELANG_VERSION}"
git checkout "v${TILELANG_VERSION}"
git submodule sync --recursive
git submodule update --init --recursive

# ─── Build ────────────────────────────────────────────────────────────────────
# Build the ROCm backend only. TileLang's CMake uses vendored HIP headers
# (3rdparty/hip-headers/) and dlopen-based HIP stubs, so no system ROCm
# installation is required on the build host.
#
# USE_ROCM and USE_CUDA must be exported as environment variables *and* passed
# via CMAKE_ARGS. version_provider.py reads os.environ directly (not CMAKE_ARGS)
# to decide the wheel name suffix; without these exports the version provider
# falls through to the cuda branch and labels the wheel +cuda instead of +rocm.
export USE_ROCM=ON
export USE_CUDA=OFF
export CMAKE_ARGS="-DUSE_ROCM=ON -DUSE_CUDA=OFF"
python -m build --wheel --no-isolation

mkdir -p "$OUTPUT_DIR"
cp dist/*.whl "$OUTPUT_DIR/"
info "TileLang ${TILELANG_VERSION} wheel: $(ls "$OUTPUT_DIR"/tilelang*.whl)"
