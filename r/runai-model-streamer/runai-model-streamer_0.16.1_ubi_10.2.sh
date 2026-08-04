#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : runai-model-streamer
# Version       : 0.16.1
# Source repo   : https://github.com/run-ai/runai-model-streamer
# Tested on     : UBI:10.2
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
# -----------------------------------------------------------------------------
#
# Builds the CORE wheel only:
#   runai_model_streamer-<version>-py3-none-manylinux2014_ppc64le.whl
#
# This wheel contains libstreamer.so (the base streaming engine) and the full
# Python API (SafetensorsStreamer, FileStreamer, DistributedStreamer).
# It does NOT include S3 support — run the companion script
# runai-model-streamer_0.16.1_ubi_10.2_wheel2_s3.sh for the S3 wheel.
#
# aws-sdk-cpp is NOT required for this wheel.
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=runai-model-streamer
PACKAGE_VERSION=${1:-0.16.1}
PACKAGE_URL=https://github.com/run-ai/runai-model-streamer
PACKAGE_DIR=runai-model-streamer
CURRENT_DIR=$(pwd)

BAZEL_VERSION="7.6.1"

# Install dependencies
yum install -y python3.12 python3.12-devel \
    git gcc gcc-c++ gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    cmake ninja-build \
    java-21-openjdk-devel \
    libcurl-devel openssl-devel libuuid-devel \
    unzip zip patch

# Configure GCC Toolset 15
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi

echo "Using gcc: $(gcc --version | head -1)"

# Configure Java
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export BAZEL_JAVAC_OPTS="-J-Xmx2g -J-Xms200m"
export PATH="$JAVA_HOME/bin:$PATH"
export PACKAGE_VERSION

# Install Python build tools
pip install --upgrade pip setuptools wheel

# Install Python runtime dependencies.
# torch and humanize are imported at module level in the core package.
# numpy and safetensors are needed for the test stage.
# torch has no ppc64le wheel on PyPI — install from the IBM wheels index.
IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"
pip install --trusted-host wheels.developerfirst.ibm.com \
    --extra-index-url "${IBM_WHEELS}" --prefer-binary \
    torch
pip install humanize "numpy>=1.24.4" "safetensors>=0.5.3"

# ---------------------------------------------------------------------------
# Step 0: Bootstrap Bazel from source
# No pre-built Bazel binary exists for ppc64le. We bootstrap from the official
# source distribution (dist.zip), which only requires a JDK and a C++ compiler.
# The compiled binary is installed to /usr/local/bin/bazel.
# ---------------------------------------------------------------------------
SKIP_BAZEL_BUILD=0

if [[ -x /usr/local/bin/bazel ]]; then
    INSTALLED_VER="$(/usr/local/bin/bazel version 2>/dev/null | awk '/Build label/{print $NF}')"
    if [[ "$INSTALLED_VER" == "$BAZEL_VERSION" ]]; then
        echo "==> Bazel $BAZEL_VERSION already installed at /usr/local/bin/bazel — skipping bootstrap"
        SKIP_BAZEL_BUILD=1
    fi
fi

if [[ "$SKIP_BAZEL_BUILD" -eq 0 ]]; then
    BAZEL_DIST_URL="https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip"
    BAZEL_DIST_ZIP="$CURRENT_DIR/bazel-${BAZEL_VERSION}-dist.zip"
    BAZEL_BUILD_DIR="$CURRENT_DIR/bazel-${BAZEL_VERSION}-src"

    echo "==> Downloading Bazel $BAZEL_VERSION source distribution"
    [[ -f "$BAZEL_DIST_ZIP" ]] \
        || curl -fL "$BAZEL_DIST_URL" -o "$BAZEL_DIST_ZIP"

    echo "==> Extracting Bazel source distribution"
    if [[ ! -d "$BAZEL_BUILD_DIR" ]]; then
        mkdir -p "$BAZEL_BUILD_DIR"
        unzip -q "$BAZEL_DIST_ZIP" -d "$BAZEL_BUILD_DIR"
    fi

    echo "==> Bootstrapping Bazel (this may take 10-20 minutes)"
    cd "$BAZEL_BUILD_DIR"
    # Bazel 7.6.1 sources are not compatible with GCC 15 (missing <cstdint>
    # transitive includes). The system gcc/g++ installed above (gcc + gcc-c++)
    # builds Bazel cleanly. We temporarily shadow the toolset-15 gcc/g++ with
    # the system versions just for this bootstrap, then restore PATH afterwards.
    ulimit -u unlimited 2>/dev/null || ulimit -u 65536 2>/dev/null || true
    SAVED_PATH="$PATH"
    export PATH="/usr/bin:/usr/sbin:${PATH}"
    export CC=/usr/bin/gcc
    export CXX=/usr/bin/g++
    export EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk --jobs=4"
    bash compile.sh
    export PATH="$SAVED_PATH"
    unset CC CXX

    install -m 0755 output/bazel /usr/local/bin/bazel
    echo "==> Bazel installed: $(bazel version 2>/dev/null | head -1)"
    cd "$CURRENT_DIR"
fi

# ---------------------------------------------------------------------------
# Step 1: Clone the repository and checkout the requested version
# ---------------------------------------------------------------------------
echo "==> Cloning runai-model-streamer"
if [[ ! -d "$CURRENT_DIR/$PACKAGE_DIR" ]]; then
    git clone $PACKAGE_URL $CURRENT_DIR/$PACKAGE_DIR
fi

cd "$CURRENT_DIR/$PACKAGE_DIR"

echo "==> Checking out version $PACKAGE_VERSION"
if git rev-parse "v${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "v${PACKAGE_VERSION}"
elif git rev-parse "${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "${PACKAGE_VERSION}"
else
    echo "ERROR: No git tag found for version '$PACKAGE_VERSION' (tried v${PACKAGE_VERSION} and ${PACKAGE_VERSION})"
    exit 1
fi

echo "==> HEAD commit: $(git log --oneline -1)"

# ---------------------------------------------------------------------------
# Step 2: Patch top-level Makefile
# The upstream Makefile uses TABS for recipe indentation.
# "build:" has a trailing space: "build: "
# ---------------------------------------------------------------------------
echo "==> Patching Makefile (ppc64le arch + build target)"

python3 - <<'PYEOF'
path = "Makefile"
with open(path) as fh:
    src = fh.read()

changed = False

if "PPC64LE_ARCH" not in src:
    src = src.replace(
        "AARCH64_ARCH := aarch64",
        "AARCH64_ARCH := aarch64\nPPC64LE_ARCH := ppc64le"
    )
    changed = True

OLD_AARCH64 = (
    "build_aarch64:\n"
    "\tmake -C cpp build ARCH=${AARCH64_ARCH} && \\\n"
    "\tmake -C py build ARCH=${AARCH64_ARCH}"
)
NEW_AARCH64_PLUS_PPC = (
    "build_aarch64:\n"
    "\tmake -C cpp build ARCH=${AARCH64_ARCH} && \\\n"
    "\tmake -C py build ARCH=${AARCH64_ARCH}\n"
    "\n"
    "build_ppc64le:\n"
    "\tmake -C cpp build ARCH=${PPC64LE_ARCH} && \\\n"
    "\tmake -C py build ARCH=${PPC64LE_ARCH}"
)
if "build_ppc64le:" not in src:
    if OLD_AARCH64 in src:
        src = src.replace(OLD_AARCH64, NEW_AARCH64_PLUS_PPC)
        changed = True
    else:
        print("  WARNING: could not find build_aarch64 block — dumping for diagnosis:")
        idx = src.find("build_aarch64")
        print(repr(src[idx:idx+200]) if idx >= 0 else "  (not found)")

OLD_BUILD = (
    "build: \n"
    "\tmake -C py clean && \\\n"
    "\tmake build_x86_64 && \\\n"
    "\tmake build_aarch64"
)
NEW_BUILD = (
    "build: \n"
    "\tmake -C py clean && \\\n"
    "\tmake build_ppc64le"
)
if NEW_BUILD not in src:
    if OLD_BUILD in src:
        src = src.replace(OLD_BUILD, NEW_BUILD)
        changed = True
    else:
        print("  WARNING: could not find expected build: recipe — dumping for diagnosis:")
        idx = src.find("build:")
        print(repr(src[idx:idx+200]) if idx >= 0 else "  (not found)")

with open(path, "w") as fh:
    fh.write(src)
print("  Makefile patched OK" if changed else "  Makefile already fully patched — skipping")
PYEOF

# ---------------------------------------------------------------------------
# Step 3: Patch cpp/.bazelrc (ppc64le platform suffix)
# ---------------------------------------------------------------------------
echo "==> Patching cpp/.bazelrc (ppc64le platform suffix)"

python3 - <<'PYEOF'
path = "cpp/.bazelrc"
with open(path) as fh:
    src = fh.read()

if "build:ppc64le" not in src:
    src = src.rstrip("\n") + "\n\nbuild:ppc64le --platform_suffix=ppc64le\n"
    with open(path, "w") as fh:
        fh.write(src)
    print("  cpp/.bazelrc patched OK")
else:
    print("  cpp/.bazelrc already patched — skipping")
PYEOF

# ---------------------------------------------------------------------------
# Step 4: Patch cpp/cc/freeres/freeres.cc
# Removes the hidden visibility attribute that causes link errors on ppc64le.
# ---------------------------------------------------------------------------
echo "==> Patching cpp/cc/freeres/freeres.cc (__freeres visibility)"

python3 - <<'PYEOF'
path = "cpp/cc/freeres/freeres.cc"
with open(path) as fh:
    src = fh.read()

old = '    __attribute__((visibility("hidden"))) void __freeres();'
new = '    void __freeres();'
if old in src:
    src = src.replace(old, new)
    with open(path, "w") as fh:
        fh.write(src)
    print("  freeres.cc patched OK")
else:
    print("  freeres.cc already patched — skipping")
PYEOF

# ---------------------------------------------------------------------------
# Step 5: Patch cpp/Makefile — build streamer only (drop s3, gcs, azure)
# ---------------------------------------------------------------------------
echo "==> Patching cpp/Makefile (streamer target only)"

python3 - <<'PYEOF'
path = "cpp/Makefile"
with open(path) as fh:
    src = fh.read()

OLD_BUILD = (
    "build:\n"
    "\tbazel build streamer:libstreamer.so \\\n"
    '\t\t"--config=${ARCH}" && \\\n'
    "\tbazel build s3:libstreamers3.so \\\n"
    "\t\t--define USE_SYSTEM_LIBS=${USE_SYSTEM_LIBS} \\\n"
    '\t\t"--config=${ARCH}" && \\\n'
    "\tbazel build gcs:libstreamergcs.so \\\n"
    "\t\t--define USE_SYSTEM_LIBS=${USE_SYSTEM_LIBS} \\\n"
    '\t\t"--config=${ARCH}" && \\\n'
    "\tbazel build azure:libstreamerazure.so \\\n"
    "\t\t--define USE_SYSTEM_LIBS=${USE_SYSTEM_LIBS} \\\n"
    '\t\t"--config=${ARCH}"'
)
# Core wheel needs libstreamer.so only
NEW_BUILD = (
    "build:\n"
    "\tbazel build streamer:libstreamer.so \\\n"
    '\t\t"--config=${ARCH}"'
)

if "libstreamergcs.so" not in src:
    print("  cpp/Makefile already patched — skipping")
elif OLD_BUILD in src:
    src = src.replace(OLD_BUILD, NEW_BUILD)
    with open(path, "w") as fh:
        fh.write(src)
    print("  cpp/Makefile patched OK")
else:
    print("  WARNING: could not find expected build: block in cpp/Makefile — dumping:")
    idx = src.find("build:")
    print(repr(src[idx:idx+500]) if idx >= 0 else "  (not found)")
PYEOF

# ---------------------------------------------------------------------------
# Step 6: Patch py/Makefile — build only the base wheel (drop gcs, azure, s3)
# ---------------------------------------------------------------------------
echo "==> Patching py/Makefile (base wheel only)"

python3 - <<'PYEOF'
path = "py/Makefile"
with open(path) as fh:
    lines = fh.readlines()

filtered = [
    line for line in lines
    if "runai_model_streamer_gcs" not in line
    and "runai_model_streamer_azure" not in line
    and "runai_model_streamer_s3" not in line
]

if len(filtered) != len(lines):
    with open(path, "w") as fh:
        fh.writelines(filtered)
    removed = len(lines) - len(filtered)
    print(f"  py/Makefile patched OK (removed {removed} line(s))")
else:
    print("  py/Makefile already patched — skipping")
PYEOF

# ---------------------------------------------------------------------------
# Step 7: Build
# ---------------------------------------------------------------------------
echo "==> Building runai-model-streamer core wheel for ppc64le (version $PACKAGE_VERSION)"
export USE_SYSTEM_LIBS=1

if ! make build ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Copy wheel to CURRENT_DIR and install it
find "$CURRENT_DIR/$PACKAGE_DIR/py" -name "runai_model_streamer-*.whl" | while read -r whl; do
    cp "$whl" "$CURRENT_DIR/"
done

pip install "$CURRENT_DIR"/runai_model_streamer-"${PACKAGE_VERSION}"-*.whl

# Run tests
if ! python3.12 - <<'PYEOF'
import sys
print(f"Python: {sys.version}")

# 1. Core package import — loads libstreamer.so via ctypes on import
print("\n[1] Importing runai_model_streamer...")
from runai_model_streamer import (
    SafetensorsStreamer,
    FileStreamer,
    DistributedStreamer,
    FileChunks,
    list_safetensors,
    pull_files,
)
print(f"    SafetensorsStreamer  : OK")
print(f"    FileStreamer        : OK")
print(f"    DistributedStreamer : OK")

# 2. Runtime dep: torch
print("\n[2] Checking torch...")
import torch
print(f"    torch version       : {torch.__version__}")

# 3. Runtime dep: humanize
print("\n[3] Checking humanize...")
import humanize
print(f"    humanize version    : {humanize.__version__}")

# 4. Runtime dep: numpy
print("\n[4] Checking numpy...")
import numpy as np
print(f"    numpy version       : {np.__version__}")

# 5. Runtime dep: safetensors
print("\n[5] Checking safetensors...")
import safetensors
print(f"    safetensors version : {safetensors.__version__}")

# 6. Verify libstreamer.so is loadable
print("\n[6] Verifying libstreamer.so loads via ctypes...")
from runai_model_streamer.libstreamer import dll
print(f"    libstreamer.so      : loaded OK")

print("\n══════════════════════════════════════════════════════")
print("  All checks passed — runai-model-streamer core OK")
print("══════════════════════════════════════════════════════")
PYEOF
then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
