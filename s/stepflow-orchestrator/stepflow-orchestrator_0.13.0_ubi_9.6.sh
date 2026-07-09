#!/bin/bash -e
# ----------------------------------------------------------------------------
# Package          : stepflow-orchestrator
# Version          : stepflow-0.13.0
# Source repo      : https://github.com/stepflow-ai/stepflow.git
# Tested on        : UBI 9.6
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ryder Salinas <rbsalinas@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
# ----------------------------------------------------------------------------

PACKAGE_NAME="stepflow"
PACKAGE_VERSION=${1:-stepflow-0.13.0}
PACKAGE_URL="https://github.com/stepflow-ai/stepflow.git"
SOURCE_ROOT="$(pwd)"

echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"

# Install system dependencies
dnf install -y \
    gcc-toolset-13 git python3.12 python3.12-devel python3.12-pip \
    make autoconf automake libtool cargo rust

export PATH="/opt/rh/gcc-toolset-13/root/usr/bin:$PATH"
export CFLAGS="-I/usr/include"
export LDFLAGS="-L/usr/lib64"

python3.12 -m pip install --upgrade pip setuptools wheel build

# Clone and checkout
cd "$SOURCE_ROOT"
rm -rf "$PACKAGE_NAME"
git clone "$PACKAGE_URL"
cd "${PACKAGE_NAME}"
git checkout "$PACKAGE_VERSION"
git submodule update --init --depth 1

# Build wheel
cd "sdks/python/stepflow-orchestrator"
python3.12 -m build --wheel --outdir "${SOURCE_ROOT}/dist/"

WHEEL=$(find "${SOURCE_ROOT}/dist" -name "stepflow_orchestrator-*.whl" | head -1)
if [ -z "$WHEEL" ]; then
    echo "ERROR: wheel not found after build"
    exit 1
fi
echo "Wheel: $WHEEL"

# Install wheel
echo "=== Installing Wheel ==="
python3.12 -m pip install "$WHEEL"

# Build protoc for testing
echo "=== Building protoc (stepflow-server dependency) for Testing ==="
cd /tmp
rm -rf protobuf-*

# Use older version for simplicity and reliability during testing
# Newer versions have more dependecnies that complicate build process
PROTOC_VERSION="21.12"
curl -LO "https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protobuf-all-${PROTOC_VERSION}.tar.gz"
tar --no-same-owner -xzf "protobuf-all-${PROTOC_VERSION}.tar.gz"
cd "protobuf-${PROTOC_VERSION}"
./configure --prefix=/usr/local

# Use N-1 cores for better performance with parallel compilation
make -j$(($(nproc)-1))
make install
ldconfig
export PATH="/usr/local/bin:$PATH"

# Build stepflow-server for testing
echo "=== Building stepflow-server for Testing ==="
cd "${SOURCE_ROOT}/${PACKAGE_NAME}/stepflow-rs"
cargo build --release --bin stepflow-server
export STEPFLOW_DEV_BINARY="${SOURCE_ROOT}/${PACKAGE_NAME}/stepflow-rs/target/release/stepflow-server"

# Run tests
echo "=== Running Tests ==="

echo "Test 1: Package installation"
python3.12 -m pip show stepflow-orchestrator

echo -e "\nTest 2: Version check"
python3.12 -c "from importlib.metadata import version; print('Version:', version('stepflow-orchestrator'))"

echo -e "\nTest 3: Import verification"
python3.12 -c "import stepflow_orchestrator; print('Import successful'); print('Location:', stepflow_orchestrator.__file__)"

echo -e "\nTest 4: Available exports"
python3.12 -c "import stepflow_orchestrator; print([x for x in dir(stepflow_orchestrator) if not x.startswith('_')])"

echo -e "\nTest 5: Functional test"
python3.12 - << 'PYEOF'
import sys, asyncio
from stepflow_orchestrator import StepflowOrchestrator, OrchestratorConfig

async def test():
    print("✓ Imports successful")
    
    async with StepflowOrchestrator.start() as orch:
        print(f"✓ Default config: {orch.url}")
    
    config = OrchestratorConfig(port=0, log_level="debug")
    async with StepflowOrchestrator.start(config) as orch:
        print(f"✓ Custom config: {orch.url}")
    
    print("✓ All tests passed")

try:
    asyncio.run(test())
except Exception as e:
    print(f"✗ Test failed: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
PYEOF

echo -e "\n=== Build Complete ==="
echo "Wheel: $WHEEL"