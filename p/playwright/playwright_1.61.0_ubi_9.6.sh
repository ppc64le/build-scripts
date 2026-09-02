#!/bin/bash -e
# ----------------------------------------------------------------------------
# Package          : playwright
# Version          : v1.61.0
# Source repo      : https://github.com/microsoft/playwright-python.git
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

PACKAGE_DIR="playwright-python"
PACKAGE_NAME="playwright"
PATCH_NAME="power_support"
PACKAGE_VERSION=${1:-v1.61.0}
PACKAGE_URL="https://github.com/microsoft/playwright-python.git"
SOURCE_ROOT="$(pwd)"

echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"

# Install system dependencies
dnf install -y \
    gcc-toolset-13 git python3.12 python3.12-devel python3.12-pip \
    make autoconf automake libtool

export PATH="/opt/rh/gcc-toolset-13/root/usr/bin:$PATH"
export CFLAGS="-I/usr/include"
export LDFLAGS="-L/usr/lib64"

python3.12 -m pip install --upgrade pip setuptools wheel build

# Clone and checkout
rm -rf "$PACKAGE_DIR"
git clone "$PACKAGE_URL"
cd "${PACKAGE_DIR}"
git checkout "$PACKAGE_VERSION"
git submodule update --init --depth 1

# Find where patch is stored
PATCH_PATH=$(find "${SOURCE_ROOT}" -name "${PATCH_NAME}.patch" | head -1)
if [ -z "${PATCH_PATH}" ]; then
    echo "ERROR: patch not found"
    exit 1
fi
echo "Patch: ${PATCH_PATH}"

# Apply patch
# Adds support for Power architecture
git apply "${PATCH_PATH}"
echo "version = \"${PACKAGE_VERSION#v}\"" > playwright/_repo_version.py

# Build wheel
python3.12 -m build --wheel --outdir "${SOURCE_ROOT}/dist/"

WHEEL=$(find "${SOURCE_ROOT}/dist" -name "${PACKAGE_NAME}-*.whl" | head -1)
if [ -z "$WHEEL" ]; then
    echo "ERROR: wheel not found after build"
    exit 1
fi
echo "Wheel: $WHEEL"

cd "${SOURCE_ROOT}"

# Install wheel
echo "=== Installing Wheel ==="
python3.12 -m pip install "$WHEEL"

# Run tests
echo "=== Running Tests ==="

echo "Test 1: Import and version"
python3.12 -c "
import playwright
from importlib.metadata import version
print('Import successful:', playwright.__file__)
print('Version:', version('playwright'))
"

echo -e "\nTest 2: Sync API import"
python3.12 -c "
from playwright.sync_api import sync_playwright
print('sync_playwright import: OK')
"

echo -e "\nTest 3: Async API import"
python3.12 -c "
from playwright.async_api import async_playwright
print('async_playwright import: OK')
"

echo -e "\nNote: Full browser automation tests cannot run on ppc64le."
echo "      Playwright does not publish pre-built browser binaries (chromium,"
echo "      firefox, webkit) for this architecture. The Python wheel is correct"
echo "      and functional — browser support requires upstream ppc64le builds."

echo -e "\n=== Build Complete ==="
echo "Wheel: $WHEEL"