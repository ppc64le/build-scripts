#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : vllm
# Version       : v0.24.0
# Source repo   : https://github.com/vllm-project/vllm.git
# Tested on     : UBI:10 (ppc64le)
# Language      : Python, C++, HIP
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
# -----------------------------------------------------------------------------
#
# ROCm installation mode (ROCM_INSTALL_MODE env var):
#   rpms   (default) - Install ROCm RPMs from a provided repo URL
#   path             - Assume ROCm is already present; use ROCM_PATH as-is
#
# PyTorch, torchvision, and torchaudio are all built from source before vLLM
# so that ROCm-enabled shared libraries are available at vLLM's CMake
# configure time.
#
# Usage:
#   ./vllm_rocm_v0.24.0_ubi_10.sh [v0.24.0]
#
# Environment variables honoured (can be set before running):
#   PACKAGE_VERSION      - vLLM tag to build (default: v0.24.0)
#   PYTORCH_VERSION      - PyTorch tag to build (default: v2.13.0)
#   TORCHVISION_VERSION  - torchvision tag to build (default: v0.28.0)
#   TORCHAUDIO_VERSION   - torchaudio tag to build (default: v2.11.0)
#   ROCM_INSTALL_MODE    - rpms (default) or path
#   ROCM_PATH            - Path to ROCm installation (default: /opt/rocm)
#   ROCM_REPO_URL        - RPM repo baseurl for ROCm
#   PYTORCH_ROCM_ARCH    - Semicolon-separated GPU targets
#                          (default: "gfx90a;gfx950")
#
# ---------------------------------------------------------------------------

set -e

PACKAGE_NAME=vllm
PACKAGE_VERSION=${1:-v0.24.0}
PACKAGE_URL=https://github.com/vllm-project/vllm.git
CURRENT_DIR=$(pwd)
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

PYTORCH_VERSION=${PYTORCH_VERSION:-v2.13.0}
PYTORCH_URL=https://github.com/pytorch/pytorch.git

TORCHVISION_VERSION=${TORCHVISION_VERSION:-v0.28.0}
TORCHVISION_URL=https://github.com/pytorch/vision.git

TORCHAUDIO_VERSION=${TORCHAUDIO_VERSION:-v2.11.0}
TORCHAUDIO_URL=https://github.com/pytorch/audio.git

ROCM_INSTALL_MODE=${ROCM_INSTALL_MODE:-"rpms"}   # rpms | path
ROCM_REPO_URL=${ROCM_REPO_URL:-"https://public.dhe.ibm.com/software/server/POWER/Linux/AMD/ROCm/RHEL/10/ppc64le"}
ROCM_PATH=${ROCM_PATH:-/opt/rocm}

# GPU architecture targets — override via env var
PYTORCH_ROCM_ARCH=${PYTORCH_ROCM_ARCH:-"gfx90a;gfx950"}

if [[ "$ROCM_INSTALL_MODE" != "rpms" && "$ROCM_INSTALL_MODE" != "path" ]]; then
    echo "ERROR: ROCM_INSTALL_MODE must be one of: rpms, path"
    exit 1
fi

echo "=== vLLM ROCm Build (torch/torchvision/torchaudio from source) ==="
echo "  PACKAGE_VERSION      : $PACKAGE_VERSION"
echo "  PYTORCH_VERSION      : $PYTORCH_VERSION"
echo "  TORCHVISION_VERSION  : $TORCHVISION_VERSION"
echo "  TORCHAUDIO_VERSION   : $TORCHAUDIO_VERSION"
echo "  ROCM_INSTALL_MODE    : $ROCM_INSTALL_MODE"
echo "  ROCM_PATH            : $ROCM_PATH"
echo "  PYTORCH_ROCM_ARCH    : $PYTORCH_ROCM_ARCH"
echo "==================================================================="

# ---------------------------------------------------------------------------
# Install system build dependencies
# ---------------------------------------------------------------------------

# Python packages must appear first (wrapper script requirement).
# Note: libdrm is not available in the UBI 10 repo — it is built from source below.
yum install -y python3.12 python3.12-devel python3.12-pip \
    gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    git make wget patch cmake ninja-build \
    openblas openblas-devel \
    libjpeg-devel libpng-devel \
    zlib-devel curl \
    meson pkgconf-pkg-config pciaccess-devel

# Configure GCC Toolset 15
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:${LD_LIBRARY_PATH:-}"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi

echo "Using gcc: $(gcc --version | head -1)"

# Use Python 3.12 for the build so all produced wheels are cp312
PYTHON=python3.12

# ---------------------------------------------------------------------------
# Build libdrm from source
# libdrm is not available in the UBI 10 package repository.  We clone the
# upstream freedesktop.org release, build it with meson, and install it into
# /usr/local so every subsequent build step can find it via pkg-config.
# ---------------------------------------------------------------------------
LIBDRM_VERSION=${LIBDRM_VERSION:-"libdrm-2.4.124"}
LIBDRM_URL="https://gitlab.freedesktop.org/mesa/drm.git"

echo "Building libdrm ${LIBDRM_VERSION} from source"
if [ -d "${CURRENT_DIR}/drm" ]; then
    echo "drm directory already exists, reusing."
    cd "${CURRENT_DIR}/drm"
    git checkout "$LIBDRM_VERSION"
else
    if ! git clone --branch "$LIBDRM_VERSION" --depth 1 "$LIBDRM_URL" "${CURRENT_DIR}/drm"; then
        echo "ERROR: Failed to clone libdrm ${LIBDRM_VERSION}"
        exit 1
    fi
    cd "${CURRENT_DIR}/drm"
fi

meson setup build \
    --prefix=/usr/local \
    --buildtype=release \
    -Damdgpu=enabled \
    -Dradeon=enabled \
    -Dintel=disabled \
    -Dnouveau=disabled \
    -Dvmwgfx=disabled \
    -Dtests=false

ninja -C build
ninja -C build install

# Make the freshly installed libdrm visible to pkg-config and the linker
export PKG_CONFIG_PATH="/usr/local/lib64/pkgconfig:/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="/usr/local/lib64:/usr/local/lib:${LD_LIBRARY_PATH:-}"
echo "libdrm installed: $(pkg-config --modversion libdrm)"

cd "${CURRENT_DIR}"

# ---------------------------------------------------------------------------
# Install Rust (required by vLLM build)
# ---------------------------------------------------------------------------
if command -v cargo &>/dev/null; then
    echo "Rust already installed: $(cargo --version)"
else
    echo "Installing Rust via rustup"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > /tmp/rust-install.sh
    sh /tmp/rust-install.sh --no-modify-path --default-toolchain stable --profile minimal -y
    rm /tmp/rust-install.sh
    export PATH="$PATH:$HOME/.cargo/bin"
    echo "Rust installed: $(cargo --version)"
fi

# ---------------------------------------------------------------------------
# MODE: rpms — install ROCm from a provided RPM repository
# ---------------------------------------------------------------------------
if [[ "$ROCM_INSTALL_MODE" == "rpms" ]]; then
    if [[ ! "$ROCM_REPO_URL" =~ ^(https?|file):// ]]; then
        echo "ERROR: ROCM_REPO_URL does not look like a valid URL (got: ${ROCM_REPO_URL})"
        exit 1
    fi
    echo "Installing ROCm from ${ROCM_REPO_URL}"

    cat > /etc/yum.repos.d/rocm.repo <<EOF
[ROCm]
name=ROCm
baseurl=${ROCM_REPO_URL}
enabled=1
gpgcheck=0
EOF
    yum install -y rocm-complete
    ROCM_PATH=/opt/rocm
fi

# Set ROCm path
export ROCM_PATH
export PATH=$ROCM_PATH/bin:$PATH
export LD_LIBRARY_PATH="${ROCM_PATH}/lib:${ROCM_PATH}/lib64:${LD_LIBRARY_PATH:-}"

# ROCm bundles its own copies of system libraries (lzma, drm, elfutils, …) under
# lib/rocm_sysdeps/lib.  In containers (e.g. UBI) these OS packages are absent,
# so we must make the sysdeps directory visible to both the runtime linker and the
# link-time linker, and point pkg-config at the bundled .pc files.
ROCM_SYSDEPS_LIB="${ROCM_PATH}/lib/rocm_sysdeps/lib"
if [[ -d "$ROCM_SYSDEPS_LIB" ]]; then
    export LD_LIBRARY_PATH="${ROCM_SYSDEPS_LIB}:${LD_LIBRARY_PATH}"
    export LDFLAGS="-Wl,-rpath,${ROCM_SYSDEPS_LIB} ${LDFLAGS:-}"
    export PKG_CONFIG_PATH="${ROCM_SYSDEPS_LIB}/pkgconfig:${PKG_CONFIG_PATH:-}"
fi

if ! command -v hipcc &>/dev/null; then
    echo "ERROR: hipcc not found under ROCM_PATH=${ROCM_PATH}. Check your ROCm installation."
    exit 1
fi
echo "ROCm hipcc: $(hipcc --version | head -1)"

# ---------------------------------------------------------------------------
# Build PyTorch from source (ROCm)
# ---------------------------------------------------------------------------

# Use OpenBLAS instead of MKL (MKL does not support Power).
# Disable CUDA/Intel tooling so cmake does not search for them.
export PYTORCH_ROCM_ARCH
export BLAS=OpenBLAS
export USE_CUDA=0
export USE_XPU=0
export USE_ROCM=1

export CMAKE_PREFIX_PATH="${ROCM_PATH}:${CMAKE_PREFIX_PATH:-}"

echo "Cloning PyTorch ${PYTORCH_VERSION}"
if [ -d "${CURRENT_DIR}/pytorch" ]; then
    echo "pytorch directory already exists, reusing."
    cd "${CURRENT_DIR}/pytorch"
    git checkout "$PYTORCH_VERSION"
else
    if ! git clone --recursive --branch "$PYTORCH_VERSION" "$PYTORCH_URL" "${CURRENT_DIR}/pytorch"; then
        echo "------------------pytorch:clone_fails---------------------------------------"
        echo "$PYTORCH_URL pytorch"
        echo "pytorch  |  $PYTORCH_URL | $PYTORCH_VERSION | GitHub | Fail |  Clone_Fails"
        exit 1
    fi
    cd "${CURRENT_DIR}/pytorch"
fi

git submodule sync
git submodule update --init --recursive

# Install PyTorch build dependencies
$PYTHON -m pip install --upgrade pip
$PYTHON -m pip install --group dev || $PYTHON -m pip install -r requirements.txt

# Run ROCm source transformation
echo "Running ROCm hipify transformation"
$PYTHON tools/amd_build/build_amd.py

# Apply patches
# Fix CUDAGuard narrowing conversion errors under GCC 14 in ROCm HIP flash-attn files
# This patch is required — fail loudly if it cannot be applied
wget https://raw.githubusercontent.com/ppc64le/build-scripts/9c57d3b2c54a629d3cf6f45095b394f85374da3f/p/pytorch-rocm/pytorch_v2.13.0_rocm_cuda_guard_narrowing.patch
git apply pytorch_v2.13.0_rocm_cuda_guard_narrowing.patch

# Fix FastGeluAsm explicit specializations rejected by AMD clang 23.0 in composable_kernel
# This patch is required — fail loudly if it cannot be applied
wget https://raw.githubusercontent.com/ppc64le/build-scripts/9c57d3b2c54a629d3cf6f45095b394f85374da3f/p/pytorch-rocm/pytorch_v2.13.0_rocm_fastgeluasm.patch
git apply --directory=third_party/composable_kernel pytorch_v2.13.0_rocm_fastgeluasm.patch

# Build
echo "Building PyTorch ${PYTORCH_VERSION} (this will take a while)"
export PYTORCH_BUILD_VERSION=${PYTORCH_VERSION#v}+rocm7.14
export PYTORCH_BUILD_NUMBER=1

# Rename the pip distribution to "torch-rocm" for ROCm stack isolation on devpi.
# The import name (torch) is unchanged — only the wheel distribution name changes.
#
# WHY sed on pyproject.toml:
#   PyTorch v2.13.0 has a pyproject.toml with [project] name = "torch".
#   setuptools>=77 (which this build requires) reads pyproject.toml as the
#   authoritative metadata source — it takes precedence over setup.py's
#   setup(name=...) call.  TORCH_PACKAGE_NAME env var only affects setup.py
#   but never reaches the wheel name because setuptools overwrites it from
#   pyproject.toml.  The only reliable fix is to patch the name in-place
#   before the build runs, exactly as torchaudio-rocm patches setup.py.
sed -i 's/^name = "torch"$/name = "torch-rocm"/' pyproject.toml
echo "Patched pyproject.toml: name = torch-rocm"

# Build wheel via setup.py directly.
# pip wheel always invokes PEP 517 (even with --no-build-isolation), which
# spawns a subprocess that does not inherit the current environment — causing
# cmake to re-configure without PYTORCH_ROCM_ARCH and fail.
# setup.py bdist_wheel runs in-process: all exported env vars are visible,
# cmake skips recompilation because build/ already exists and targets are
# up to date, and setuptools reads the patched pyproject.toml for the name.
echo "Building distribution wheel"
if ! MAX_JOBS=$(nproc) $PYTHON setup.py bdist_wheel --dist-dir "${CURRENT_DIR}/dist"; then
    echo "------------------pytorch:Install_fails-------------------------------------"
    echo "$PYTORCH_URL pytorch"
    echo "pytorch  |  $PYTORCH_URL | $PYTORCH_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Install from the renamed wheel so pip registers it as torch-rocm
$PYTHON -m pip install --no-build-isolation "${CURRENT_DIR}/dist"/torch_rocm-*.whl

# Verify torch is importable and ROCm is visible through it
echo "Verifying torch install"
cd "${CURRENT_DIR}"
export ROCPROFILER_LOG_LEVEL=0
$PYTHON -c "import torch; print('torch version :', torch.__version__); print('ROCm available:', torch.cuda.is_available())"

# ---------------------------------------------------------------------------
# Build torchvision from source (ROCm)
# ---------------------------------------------------------------------------
echo "Cloning torchvision ${TORCHVISION_VERSION}"
if [ -d "${CURRENT_DIR}/vision" ]; then
    echo "vision directory already exists, reusing."
    cd "${CURRENT_DIR}/vision"
    git checkout "$TORCHVISION_VERSION"
else
    if ! git clone --branch "$TORCHVISION_VERSION" "$TORCHVISION_URL" "${CURRENT_DIR}/vision"; then
        echo "------------------torchvision:clone_fails---------------------------------------"
        echo "$TORCHVISION_URL torchvision"
        echo "torchvision  |  $TORCHVISION_URL | $TORCHVISION_VERSION | GitHub | Fail |  Clone_Fails"
        exit 1
    fi
    cd "${CURRENT_DIR}/vision"
fi

TORCHVISION_PATCH_BASE_URL=${TORCHVISION_PATCH_BASE_URL:-"https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/t/torchvision"}

# License exclusion patch — required; removes SWAG CC-BY-NC-4.0 licensed
# models (regnet.py, vision_transformer SWAG weights) from the wheel.
TORCHVISION_LICENSE_PATCH="0001-Exclude-source-that-has-commercial-license_v0.28.0.patch"
wget -q -O "${CURRENT_DIR}/${TORCHVISION_LICENSE_PATCH}" "${TORCHVISION_PATCH_BASE_URL}/${TORCHVISION_LICENSE_PATCH}"
git apply "${CURRENT_DIR}/${TORCHVISION_LICENSE_PATCH}"

# Patch out the git-sha injection in setup.py that breaks reproducible builds
sed -i '/elif sha != "Unknown":/,+1d' setup.py

# Rename the distribution to "torchvision-rocm" via the env var that
# torchvision's setup.py already supports (TORCHVISION_PACKAGE_NAME).
# The import name (torchvision) is unchanged — only the pip distribution name changes.
export TORCHVISION_PACKAGE_NAME="torchvision-rocm"

# Tell torchvision's get_requirements() to list "torch-rocm" as its torch
# dependency instead of "torch". torchvision's setup.py reads TORCH_PACKAGE_NAME
# at install_requires time. Without this, pip fails to install the wheel because
# it looks for "torch" which doesn't exist — only "torch-rocm" is installed.
export TORCH_PACKAGE_NAME="torch-rocm"

echo "Building torchvision-rocm wheel"

export TORCH_CMAKE_PREFIX=$($PYTHON -c 'import torch; print(torch.utils.cmake_prefix_path)')
export CMAKE_PREFIX_PATH="${TORCH_CMAKE_PREFIX}:${ROCM_PATH}:${CMAKE_PREFIX_PATH:-}"

export BUILD_VERSION="${TORCHVISION_VERSION#v}"
export SETUPTOOLS_SCM_PRETEND_VERSION="${BUILD_VERSION}"

if ! MAX_JOBS=$(nproc) $PYTHON setup.py bdist_wheel --dist-dir "${CURRENT_DIR}"; then
    echo "------------------torchvision:Install_fails-------------------------------------"
    echo "$TORCHVISION_URL torchvision"
    echo "torchvision  |  $TORCHVISION_URL | $TORCHVISION_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

TORCHVISION_WHL=$(ls "${CURRENT_DIR}"/torchvision_rocm-${BUILD_VERSION}-*.whl)
echo "Built wheel: $(basename $TORCHVISION_WHL)"
$PYTHON -m pip install --find-links "${CURRENT_DIR}" "$TORCHVISION_WHL"

# Verify torchvision is importable
echo "Verifying torchvision install"
cd "${CURRENT_DIR}"
$PYTHON -c "import torchvision; print('torchvision version:', torchvision.__version__)"

# ---------------------------------------------------------------------------
# Build torchaudio from source (ROCm)
# ---------------------------------------------------------------------------
echo "Cloning torchaudio ${TORCHAUDIO_VERSION}"
if [ -d "${CURRENT_DIR}/audio" ]; then
    echo "audio directory already exists, reusing."
    cd "${CURRENT_DIR}/audio"
    git checkout "$TORCHAUDIO_VERSION"
else
    if ! git clone --branch "$TORCHAUDIO_VERSION" "$TORCHAUDIO_URL" "${CURRENT_DIR}/audio"; then
        echo "------------------torchaudio:clone_fails---------------------------------------"
        echo "$TORCHAUDIO_URL torchaudio"
        echo "torchaudio  |  $TORCHAUDIO_URL | $TORCHAUDIO_VERSION | GitHub | Fail |  Clone_Fails"
        exit 1
    fi
    cd "${CURRENT_DIR}/audio"
fi

TORCHAUDIO_PATCH_BASE_URL=${TORCHAUDIO_PATCH_BASE_URL:-"https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/t/torchaudio"}

# License exclusion patch — required; removes commercially licensed source files
TORCHAUDIO_LICENSE_PATCH="0001-Excluded-source-that-has-commercial-license-new.patch"
wget -q -O "${CURRENT_DIR}/${TORCHAUDIO_LICENSE_PATCH}" "${TORCHAUDIO_PATCH_BASE_URL}/${TORCHAUDIO_LICENSE_PATCH}"
git apply "${CURRENT_DIR}/${TORCHAUDIO_LICENSE_PATCH}"
echo "Applied torchaudio license exclusion patch"

# Rename distribution to torchaudio-rocm for ROCm stack isolation.
# torchaudio's setup.py hardcodes name="torchaudio" with no env var override,
# so we patch it directly. The import name (torchaudio) is unchanged.
sed -i 's/name="torchaudio"/name="torchaudio-rocm"/' setup.py

export BUILD_VERSION="${TORCHAUDIO_VERSION#v}"
export SETUPTOOLS_SCM_PRETEND_VERSION="${BUILD_VERSION}"

export TORCH_CMAKE_PREFIX=$($PYTHON -c 'import torch; print(torch.utils.cmake_prefix_path)')
export CMAKE_PREFIX_PATH="${TORCH_CMAKE_PREFIX}:${ROCM_PATH}:${CMAKE_PREFIX_PATH:-}"

# Disable optional media deps — not needed for the ROCm wheel
export USE_FFMPEG=OFF
export BUILD_SOX=OFF
export USE_OPENMP=OFF
export BUILD_TORCHAUDIO_PYTHON_EXTENSION=ON

$PYTHON -m pip install --upgrade setuptools wheel

echo "Building torchaudio-rocm wheel"
if ! $PYTHON -m pip wheel . --no-build-isolation --no-deps -w "${CURRENT_DIR}"; then
    echo "------------------torchaudio:Install_fails-------------------------------------"
    echo "$TORCHAUDIO_URL torchaudio"
    echo "torchaudio  |  $TORCHAUDIO_URL | $TORCHAUDIO_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

TORCHAUDIO_WHL=$(ls "${CURRENT_DIR}"/torchaudio_rocm-${BUILD_VERSION}-*.whl)
echo "Built wheel: $(basename $TORCHAUDIO_WHL)"
$PYTHON -m pip install "$TORCHAUDIO_WHL"

# Verify torchaudio is importable
echo "Verifying torchaudio install"
cd "${CURRENT_DIR}"
$PYTHON -c "import torchaudio; print('torchaudio version:', torchaudio.__version__)"

# ---------------------------------------------------------------------------
# Clone vLLM
# ---------------------------------------------------------------------------
echo "Cloning vLLM ${PACKAGE_VERSION}"
if [ -d "${CURRENT_DIR}/vllm/.git" ]; then
    echo "vllm directory already exists, reusing."
    cd "${CURRENT_DIR}/vllm"
    git fetch --tags origin
    git checkout "$PACKAGE_VERSION"
else
    if ! git clone "$PACKAGE_URL" "${CURRENT_DIR}/vllm"; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Clone_Fails"
        exit 1
    fi
    cd "${CURRENT_DIR}/vllm"
    git checkout "$PACKAGE_VERSION"
fi

echo "Current vLLM commit:"
git --no-pager log -1 --oneline

# ---------------------------------------------------------------------------
# Apply vLLM patches
# ---------------------------------------------------------------------------

# use_existing_torch.py — removes vLLM's bundled torch build in favour of
# the torch-rocm wheel already installed above
echo "Running vLLM use_existing_torch.py patch"
[[ -f "use_existing_torch.py" ]] || { echo "ERROR: use_existing_torch.py not found"; exit 1; }
$PYTHON use_existing_torch.py

# Patch requirements/build/rocm.txt:
#   1. Relax triton pin (==3.6.0 → >=3.6.0) for ppc64le wheel compatibility
#   2. Remove amdsmi PyPI pin — installed from system ROCm below
REQ_FILE="requirements/build/rocm.txt"
[[ -f "$REQ_FILE" ]] || { echo "ERROR: $REQ_FILE not found"; exit 1; }

if grep -q '^triton==3\.6\.0$' "$REQ_FILE"; then
    sed -i 's/^triton==3\.6\.0$/triton>=3.6.0/' "$REQ_FILE"
    echo "Patched $REQ_FILE: triton==3.6.0 -> triton>=3.6.0"
elif grep -q '^triton>=3\.6\.0$' "$REQ_FILE"; then
    echo "$REQ_FILE already patched for triton>=3.6.0"
else
    echo "ERROR: Could not find expected triton==3.6.0 line in $REQ_FILE"
    exit 1
fi

if grep -q '^amdsmi' "$REQ_FILE"; then
    sed -i '/^amdsmi/d' "$REQ_FILE"
    echo "Patched $REQ_FILE: removed amdsmi line (installed from system ROCm instead)"
fi

# Inject ROCm bitcode path into CMAKE_HIP_FLAGS in setup.py
ROCM_BITCODE_DIR="$ROCM_PATH/lib/llvm/amdgcn/bitcode"
[[ -d "$ROCM_BITCODE_DIR" ]] || { echo "ERROR: ROCm bitcode directory not found: $ROCM_BITCODE_DIR"; exit 1; }

echo "Patching setup.py CMAKE_HIP_FLAGS with ROCm bitcode path"
$PYTHON - <<PY
from pathlib import Path

setup_file = Path("setup.py")
text = setup_file.read_text()

hip_flag = '            "-DCMAKE_HIP_FLAGS=--rocm-device-lib-path=${ROCM_BITCODE_DIR}/",\n'

target = '''cmake_args = [
            "-DCMAKE_BUILD_TYPE={}".format(cfg),
            "-DVLLM_TARGET_DEVICE={}".format(VLLM_TARGET_DEVICE),
        ]'''

replacement = '''cmake_args = [
            "-DCMAKE_BUILD_TYPE={}".format(cfg),
            "-DVLLM_TARGET_DEVICE={}".format(VLLM_TARGET_DEVICE),
''' + hip_flag + '''        ]'''

if hip_flag.strip() in text:
    print("setup.py already contains desired CMAKE_HIP_FLAGS patch.")
elif target in text:
    text = text.replace(target, replacement, 1)
    setup_file.write_text(text)
    print("setup.py patched successfully.")
else:
    raise SystemExit("Could not find the expected first cmake_args block in setup.py.")
PY

# Patch runai-model-streamer: replace [s3,gcs,azure] extras with [s3] only
# (gcs and azure extras are not available for ppc64le)
echo "Patching runai-model-streamer extras"
$PYTHON - <<'PY'
from pathlib import Path

files_to_patch = [
    "setup.py",
    "requirements/rocm.txt",
    "requirements/test/rocm.in",
    "requirements/test/nightly-torch.txt",
    "requirements/test/cuda.in",
]

old_extras = '"runai": ["runai-model-streamer[s3,gcs,azure] >= 0.15.7"],'
new_extras = '"runai": ["runai-model-streamer[s3] >= 0.15.7"],'
old_base   = "runai-model-streamer[s3,gcs,azure]=="
new_base   = "runai-model-streamer[s3]=="

patched = 0
for fp in files_to_patch:
    p = Path(fp)
    if not p.exists():
        print(f"  skip {fp} (not found)")
        continue
    text = p.read_text()
    original = text
    if fp == "setup.py":
        if old_extras in text:
            text = text.replace(old_extras, new_extras, 1)
            print(f"  patched {fp}: extras declaration")
            patched += 1
        elif new_extras in text:
            print(f"  {fp}: already patched")
        else:
            raise SystemExit(f"Could not find expected pattern in {fp}")
    else:
        if old_base in text:
            text = text.replace(old_base, new_base)
            print(f"  patched {fp}: base requirement")
            patched += 1
        elif new_base in text:
            print(f"  {fp}: already patched")
        else:
            print(f"  skip {fp} (no runai-model-streamer found)")
            continue
    if text != original:
        p.write_text(text)
print(f"Patched {patched} file(s)")
PY

# ---------------------------------------------------------------------------
# Build vLLM wheel
# ---------------------------------------------------------------------------
cd "${CURRENT_DIR}/vllm"

# ROCm build environment is already exported; set vLLM-specific additions
export CMAKE_PREFIX_PATH="${ROCM_PATH}:${CMAKE_PREFIX_PATH:-}"

echo "Installing vLLM ROCm build requirements"
[[ -f "requirements/build/rocm.txt" ]] || { echo "ERROR: requirements/build/rocm.txt not found"; exit 1; }
$PYTHON -m pip install -r requirements/build/rocm.txt

# Install matching AMDSMI Python bindings from system ROCm (not PyPI)
AMDSMI_SRC="$ROCM_PATH/share/amd_smi"
[[ -d "$AMDSMI_SRC" ]] || { echo "ERROR: AMDSMI source not found: $AMDSMI_SRC"; exit 1; }
AMDSMI_TMP=$(mktemp -d)
cp -a "$AMDSMI_SRC/." "$AMDSMI_TMP/"
$PYTHON -m pip install --force-reinstall --no-deps "$AMDSMI_TMP"
rm -rf "$AMDSMI_TMP"
echo "Installed AMDSMI from system ROCm"

echo "Building vLLM ROCm wheel (this will take a while)"
if ! VLLM_TARGET_DEVICE="rocm" $PYTHON setup.py bdist_wheel --dist-dir "${CURRENT_DIR}/dist"; then
    echo "------------------$PACKAGE_NAME:install_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

echo "Built vLLM wheel(s):"
ls -lh "${CURRENT_DIR}/dist"/vllm-*.whl

$PYTHON -m pip install "${CURRENT_DIR}/dist"/vllm-*.whl

# ---------------------------------------------------------------------------
# Import test
# ---------------------------------------------------------------------------
echo "Running import test"
cd "${CURRENT_DIR}"

if ! $PYTHON -c "import vllm; print('vllm version:', vllm.__version__)"; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi