#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : py-spy
# Version          : 0.4.2
# Source repo      : https://github.com/benfred/py-spy
# Tested on        : UBI:10.2
# Language         : Python, Rust
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Sharath P J <sharath.pj@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=py-spy
PACKAGE_VERSION=${1:-0.4.2}
PACKAGE_URL=https://github.com/benfred/py-spy
PACKAGE_DIR=py-spy-${PACKAGE_VERSION}
CURRENT_DIR=$(pwd)

# Install system dependencies
yum install -y python3.12 python3.12-devel python3.12-pip \
    gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    git wget make cmake \
    openssl-devel zlib-devel

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

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
source "$HOME/.cargo/env"
rustc --version
cargo --version

# Install Python build tools
pip install --upgrade pip setuptools wheel build
pip install maturin

# Clone repository
cd "$CURRENT_DIR"
git clone "$PACKAGE_URL" "$PACKAGE_DIR"
cd "$PACKAGE_DIR"

# Checkout version
if git rev-parse "v${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "v${PACKAGE_VERSION}"
elif git rev-parse "${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "${PACKAGE_VERSION}"
else
    echo "ERROR: No git tag found for version '${PACKAGE_VERSION}'"
    exit 1
fi

# Build wheel using maturin
if ! maturin build --release -o dist; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Install the wheel
if ! pip install dist/*.whl; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Copy wheel to CURRENT_DIR for wrapper script
cp dist/*.whl "$CURRENT_DIR/"

# Smoke test - verify py-spy binary works
# Note: py-spy uses maturin with bindings = "bin" (binary-only, no Python module to import)
if ! py-spy --version ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
fi

# Functional test: use py-spy dump to verify profiling works across all Python versions.
# py-spy dump reads live stack frames via --pid without invoking the inferno flamegraph
# renderer, so it avoids the "No stack counts found" issue that py-spy record can hit on
# source-built Python interpreters (e.g. Python 3.13 compiled from python.org tarballs).
python3.12 - <<'PYEOF'
import subprocess
import sys
import time
import signal
import os

# Start a long-running Python process to profile
target = subprocess.Popen(
    [sys.executable, '-c',
     'import time\n'
     'while True:\n'
     '    time.sleep(0.1)\n'],
)

try:
    # Give the target process a moment to start
    time.sleep(1)

    result = subprocess.run(
        ['py-spy', 'dump', '--pid', str(target.pid)],
        capture_output=True,
        text=True,
        timeout=15,
    )

    if result.returncode != 0:
        print(f"py-spy dump failed (rc={result.returncode}):\n{result.stderr}")
        sys.exit(1)

    if not result.stdout.strip():
        print("py-spy dump produced no output")
        sys.exit(1)

    print("py-spy dump test passed")
    print(result.stdout[:200])
finally:
    target.terminate()
    target.wait()
PYEOF

if [ $? -ne 0 ]; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
fi

echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
exit 0
