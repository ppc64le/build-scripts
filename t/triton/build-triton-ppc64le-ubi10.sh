#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : triton
# Version       : 3.6.0
# Source repo   : https://github.com/triton-lang/triton
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
# Clones triton at the requested version tag, builds the pinned LLVM from
# source (required on ppc64le — no pre-built binary is provided upstream),
# then builds the Triton Python wheel.
#
# Output wheel:
#   <output-dir>/triton-3.6.0-cpXY-cpXY-linux_ppc64le.whl
#
# Requirements (must be pre-installed):
#   - Python >= 3.9 (with pip, venv, and python3-devel headers)
#   - GCC Toolset 15  (/opt/rh/gcc-toolset-15)
#   - cmake >= 3.20, ninja, git, zlib-devel
#
# Usage:
#   ./build-triton-ppc64le-ubi10.sh [--version 3.6.0] [--workdir $HOME]
#                             [--python /usr/bin/python3.11]
#                             [--output-dir $HOME/vllm-wheels]
#                             [--skip-llvm-build]
#
set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"

# ─── Defaults ─────────────────────────────────────────────────────────────────
TRITON_VERSION="3.6.0"
WORK_DIR="${HOME}"
OUTPUT_DIR=""          # resolved to ${WORK_DIR}/vllm-wheels after arg parsing
PYTHON_BIN="/usr/bin/python3.13"
SKIP_LLVM_BUILD=0

# ─── Helpers ──────────────────────────────────────────────────────────────────
die()  { echo "ERROR: $*" >&2; exit 1; }
info() { echo "==> $*"; }

usage() {
    cat <<EOF
Usage:
  $SCRIPT_NAME [options]

Options:
  --version VERSION     Triton version tag to build (default: $TRITON_VERSION)
  --workdir DIR         Parent directory for clones and the venv (default: $WORK_DIR)
  --python PATH         Full path to Python executable (default: system python3)
  --output-dir DIR      Directory to copy the built wheel into (default: <workdir>/vllm-wheels)
  --skip-llvm-build     Skip cloning/building LLVM (requires LLVM_SYSPATH to be set)
  -h, --help            Show this help and exit
EOF
}

# ─── Argument parsing ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)         TRITON_VERSION="$2"; shift 2 ;;
        --workdir)         WORK_DIR="$2";        shift 2 ;;
        --python)          PYTHON_BIN="$2";      shift 2 ;;
        --output-dir)      OUTPUT_DIR="$2";       shift 2 ;;
        --skip-llvm-build) SKIP_LLVM_BUILD=1;    shift   ;;
        -h|--help)         usage; exit 0 ;;
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
    zlib-devel       \
    python3.13       \
    python3.13-devel

REPO_DIR="$WORK_DIR/triton"
LLVM_BUILD_DIR="$WORK_DIR/llvm-project"
LLVM_INSTALL_DIR="$WORK_DIR/llvm-install"

# ─── Resolve Python ───────────────────────────────────────────────────────────
info "Resolving Python executable"
if [[ -n "$PYTHON_BIN" ]]; then
    [[ "$PYTHON_BIN" == /* ]] || die "--python must be an absolute path"
    [[ -x "$PYTHON_BIN" ]] || die "Python executable not found or not executable: $PYTHON_BIN"
else
    PYTHON_BIN="$(command -v python3)" \
        || die "python3 not found in PATH — use --python /path/to/python"
fi
"$PYTHON_BIN" -c 'import sys' || die "Selected Python is not runnable: $PYTHON_BIN"
echo "Using Python: $PYTHON_BIN"
echo "Python version: $("$PYTHON_BIN" -c 'import sys; print(sys.version)')"

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

# ─── Step 1: Clone triton and checkout the requested version ──────────────────
info "Cloning triton into $REPO_DIR"
if [[ -d "$REPO_DIR" ]]; then
    info "Directory already exists — skipping clone"
else
    git clone https://github.com/triton-lang/triton.git "$REPO_DIR"
fi

cd "$REPO_DIR"

info "Checking out v${TRITON_VERSION}"
if git rev-parse "v${TRITON_VERSION}" &>/dev/null; then
    git checkout "v${TRITON_VERSION}"
elif git rev-parse "${TRITON_VERSION}" &>/dev/null; then
    git checkout "${TRITON_VERSION}"
else
    die "No git tag found for version '$TRITON_VERSION' (tried v${TRITON_VERSION} and ${TRITON_VERSION})"
fi

git submodule sync --recursive
git submodule update --init --recursive

info "HEAD commit: $(git log --oneline -1)"

# ─── Step 2: Read the LLVM commit hash pinned by this Triton release ──────────
LLVM_HASH_FILE="$REPO_DIR/cmake/llvm-hash.txt"
[[ -f "$LLVM_HASH_FILE" ]] || die "Expected LLVM hash file not found: $LLVM_HASH_FILE"
LLVM_COMMIT="$(cat "$LLVM_HASH_FILE")"
info "Triton requires LLVM commit: $LLVM_COMMIT"

# ─── Step 3: Build LLVM from source ───────────────────────────────────────────
# Triton does not provide pre-built LLVM binaries for ppc64le.
# We build the minimum set of LLVM targets needed by Triton:
#   PowerPC (ppc64le native codegen), NVPTX (GPU), AMDGPU (GPU), WebAssembly
#   (WASM backend), and the MLIR + LLD libraries that Triton requires.
if [[ "$SKIP_LLVM_BUILD" -eq 1 ]]; then
    [[ -n "${LLVM_SYSPATH:-}" ]] \
        || die "--skip-llvm-build requires LLVM_SYSPATH to already be set in the environment"
    info "Skipping LLVM build — using LLVM_SYSPATH=$LLVM_SYSPATH"
else
    info "Cloning llvm-project into $LLVM_BUILD_DIR"
    if [[ -d "$LLVM_BUILD_DIR" ]]; then
        info "llvm-project directory already exists — skipping clone"
    else
        git clone https://github.com/llvm/llvm-project.git "$LLVM_BUILD_DIR"
    fi

    cd "$LLVM_BUILD_DIR"
    info "Checking out pinned LLVM commit $LLVM_COMMIT"
    git fetch origin "$LLVM_COMMIT" 2>/dev/null \
        || git fetch origin       # fallback: fetch all and hope it's reachable
    git checkout "$LLVM_COMMIT"

    LLVM_CMAKE_BUILD="$LLVM_BUILD_DIR/build"
    mkdir -p "$LLVM_CMAKE_BUILD"
    cd "$LLVM_CMAKE_BUILD"

    info "Configuring LLVM (this may take a while)"

    NPROC="$(nproc)"
    MAX_JOBS="${MAX_JOBS:-$(( NPROC < 16 ? NPROC : 16 ))}"
    export MAX_JOBS

    cmake ../llvm \
        -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$LLVM_INSTALL_DIR" \
        -DLLVM_ENABLE_PROJECTS="mlir;lld;clang" \
        -DLLVM_TARGETS_TO_BUILD="PowerPC;NVPTX;AMDGPU;WebAssembly" \
        -DLLVM_ENABLE_ASSERTIONS=OFF \
        -DLLVM_INSTALL_UTILS=ON \
        -DMLIR_ENABLE_BINDINGS_PYTHON=OFF \
        -DCMAKE_C_COMPILER=gcc \
        -DCMAKE_CXX_COMPILER=g++ \
        -DLLVM_PARALLEL_LINK_JOBS=4

    info "Building LLVM (MAX_JOBS=$MAX_JOBS)"
    ninja -j"$MAX_JOBS" install

    export LLVM_SYSPATH="$LLVM_INSTALL_DIR"
    info "LLVM installed to $LLVM_SYSPATH"

    cd "$REPO_DIR"
fi

# ─── Step 4: Create / activate virtual environment ────────────────────────────
VENV_DIR="$REPO_DIR/venv"
info "Setting up Python venv at $VENV_DIR"
if [[ ! -d "$VENV_DIR" ]]; then
    "$PYTHON_BIN" -m venv "$VENV_DIR"
fi
# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

python -m pip install --upgrade pip setuptools wheel ninja cmake pybind11

# ─── Step 5: Build the Triton wheel ───────────────────────────────────────────
# setup.py lives at the repo root (not under python/).
# LLVM_SYSPATH tells setup.py where our built LLVM lives, bypassing the
# upstream prebuilt-binary download (which has no ppc64le image).
# TRITON_BUILD_WITH_CLANG_LLD=0 keeps the GCC toolchain active.
info "Building Triton wheel (version $TRITON_VERSION) for ppc64le"

export LLVM_SYSPATH
export TRITON_BUILD_WITH_CLANG_LLD=0
# Prevent setup.py from downloading CUDA/NVIDIA binaries (ptxas, nvdisasm,
# cuobjdump, cudart headers, cupti).  No ppc64le packages exist on NVIDIA's
# CDN and the NVIDIA backend is not used on this platform anyway.
export TRITON_OFFLINE_BUILD=1
# Disable the proton profiler sub-component.  When TRITON_OFFLINE_BUILD=1 is
# set, proton's build requires JSON_SYSPATH to be pre-defined; disabling it
# entirely avoids that requirement and reduces build time.
export TRITON_BUILD_PROTON=OFF

cd "$REPO_DIR"
python setup.py bdist_wheel

# ─── Step 6: Copy wheel to staging area and report ────────────────────────────
info "Build complete. Wheels:"
find "$REPO_DIR/dist" -name "*.whl" | sort | while read -r whl; do
    echo "  $whl"
done

mkdir -p "$OUTPUT_DIR"
cp "$REPO_DIR"/dist/triton-*.whl "$OUTPUT_DIR/"
info "Triton wheel copied to $OUTPUT_DIR"

