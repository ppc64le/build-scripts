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

# Test py-spy record functionality with a simple Python script
# Note: py-spy is a binary-only package (bindings = "bin"), so we use the py-spy binary directly
python3.12 - <<'PYEOF'
import subprocess
import sys
import tempfile
import os

# Create a simple Python script to profile
test_script = """
import time
def foo():
    time.sleep(0.1)
    return 42

def bar():
    for i in range(5):
        foo()
    return "done"

if __name__ == "__main__":
    bar()
"""

with tempfile.NamedTemporaryFile(mode='w', suffix='.py', delete=False) as f:
    f.write(test_script)
    script_path = f.name

try:
    # Run py-spy record with a short duration (use binary directly, not -m py_spy)
    result = subprocess.run(
        ['py-spy', 'record', '-o', '/tmp/profile.svg', '--', sys.executable, script_path],
        capture_output=True,
        text=True,
        timeout=30
    )
    if result.returncode != 0:
        print(f"py-spy record failed: {result.stderr}")
        sys.exit(1)
    
    # Check if output file was created
    if not os.path.exists('/tmp/profile.svg'):
        print("Profile output file not created")
        sys.exit(1)
    
    print("py-spy record test passed")
finally:
    if os.path.exists(script_path):
        os.unlink(script_path)
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
