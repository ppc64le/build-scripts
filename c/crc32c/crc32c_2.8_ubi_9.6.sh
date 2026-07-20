#!/bin/bash -e
# ----------------------------------------------------------------------------
# Package          : crc32c
# Version          : v2.8
# Source repo      : https://github.com/ICRAR/crc32c.git
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

PACKAGE_DIR="crc32c"
PACKAGE_NAME="crc32c"
PACKAGE_VERSION=${1:-v2.8}
PACKAGE_URL="https://github.com/ICRAR/crc32c.git"
SOURCE_ROOT="$(pwd)"

echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"

# Install system dependencies
dnf install -y gcc-toolset-13 git python3.12 python3.12-devel python3.12-pip

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
import ${PACKAGE_NAME}
from importlib.metadata import version
print('Import successful:', ${PACKAGE_NAME}.__file__)
print('Version:', version('${PACKAGE_NAME}'))
print('Import and version: OK')
"

echo "Test 2: Basic checksum correctness"
python3.12 -c "
import crc32c
result = crc32c.crc32c(b'hello world')
expected = 0xC99465AA
assert result == expected, f'Expected {expected:#010x}, got {result:#010x}'
print(f'crc32c(b\"hello world\") = {result:#010x}: OK')
"

echo "Test 3: Empty input"
python3.12 -c "
import crc32c
result = crc32c.crc32c(b'')
expected = 0x00000000
assert result == expected, f'Expected {expected:#010x}, got {result:#010x}'
print(f'crc32c(b\"\") = {result:#010x}: OK')
"

echo "Test 4: Incremental / chained checksum"
python3.12 -c "
import crc32c
crc = crc32c.crc32c(b'hello ')
crc = crc32c.crc32c(b'world', crc)
expected = crc32c.crc32c(b'hello world')
assert crc == expected, f'Incremental mismatch: {crc:#010x} != {expected:#010x}'
print(f'Incremental checksum = {crc:#010x}: OK')
"

echo "Test 5: Single zero byte"
python3.12 -c "
import crc32c
result = crc32c.crc32c(b'\x00')
expected = 0x527D5351
assert result == expected, f'Expected {expected:#010x}, got {result:#010x}'
print(f'crc32c(b\"\\x00\") = {result:#010x}: OK')
"

echo "Test 6: All 0xFF bytes"
python3.12 -c "
import crc32c
result = crc32c.crc32c(b'\xff' * 32)
print(f'crc32c(0xFF * 32) = {result:#010x}: OK (non-zero check)')
assert result != 0, 'Expected non-zero checksum for 0xFF buffer'
"

echo "Test 7: Bytearray and memoryview inputs"
python3.12 -c "
import crc32c
data = b'hello world'
ref = crc32c.crc32c(data)
ba_result  = crc32c.crc32c(bytearray(data))
mv_result  = crc32c.crc32c(memoryview(data))
assert ba_result == ref,  f'bytearray mismatch: {ba_result:#010x}'
assert mv_result == ref,  f'memoryview mismatch: {mv_result:#010x}'
print(f'bytearray input  = {ba_result:#010x}: OK')
print(f'memoryview input = {mv_result:#010x}: OK')
"

echo "Test 8: Large buffer (1 MB)"
python3.12 -c "
import crc32c
data = b'A' * (1024 * 1024)
result = crc32c.crc32c(data)
assert isinstance(result, int) and 0 <= result <= 0xFFFFFFFF, 'Result out of uint32 range'
print(f'crc32c(1 MB of A) = {result:#010x}: OK')
"

echo "Test 9: Hardware acceleration flag"
python3.12 -c "
import crc32c
hw = crc32c.hardware_based
print(f'Hardware acceleration: {hw}')
print('Hardware flag check: OK')
"

echo -e "\n=== Build Complete ==="