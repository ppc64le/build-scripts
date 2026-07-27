#!/bin/bash -e
# ----------------------------------------------------------------------------
# Package          : fastuuid
# Version          : 0.14.0
# Source repo      : https://github.com/fastuuid/fastuuid.git
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

PACKAGE_DIR="fastuuid"
PACKAGE_NAME="fastuuid"
PACKAGE_VERSION=${1:-0.14.0}
PACKAGE_URL="https://github.com/fastuuid/fastuuid.git"
SOURCE_ROOT="$(pwd)"

echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"

# Install system dependencies
dnf install -y gcc-toolset-13 git python3.12 python3.12-devel python3.12-pip

export PATH="/opt/rh/gcc-toolset-13/root/usr/bin:$PATH"
export CFLAGS="-I/usr/include"
export LDFLAGS="-L/usr/lib64"

python3.12 -m pip install --upgrade pip build

# Clone and checkout
rm -rf "$PACKAGE_DIR"
git clone "$PACKAGE_URL"
cd "${PACKAGE_DIR}"
git checkout "$PACKAGE_VERSION"
git submodule update --init --depth 1

# Find where patch is stored
PATCH_PATH=$(find "${SOURCE_ROOT}" -name "${PACKAGE_NAME}_${PACKAGE_VERSION}.patch" | head -1)
if [ -z "${PATCH_PATH}" ]; then
    echo "ERROR: patch not found"
    exit 1
fi
echo "Patch: ${PATCH_PATH}"

# Apply patch
# Corrects use of deprecated type alias `uuid::Context`: renamed to `ContextV1`
git apply "${PATCH_PATH}"

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

echo "Test 2: Generate UUID4"
python3.12 -c "
import fastuuid
u = fastuuid.uuid4()
assert isinstance(u, fastuuid.UUID), 'uuid4() did not return a UUID'
assert u.version == 4, f'Expected version 4, got {u.version}'
print('uuid4():', u)
print('UUID4: OK')
"

echo "Test 3: Generate UUID1"
python3.12 -c "
import fastuuid
u = fastuuid.uuid1()
assert isinstance(u, fastuuid.UUID), 'uuid1() did not return a UUID'
assert u.version == 1, f'Expected version 1, got {u.version}'
print('uuid1():', u)
print('UUID1: OK')
"

echo "Test 4: UUID uniqueness"
python3.12 -c "
import fastuuid
uuids = {str(fastuuid.uuid4()) for _ in range(1000)}
assert len(uuids) == 1000, f'Collision detected: only {len(uuids)} unique UUIDs from 1000'
print('1000 unique UUID4s generated')
print('Uniqueness: OK')
"

echo "Test 5: UUID string format"
python3.12 -c "
import fastuuid, re
u = fastuuid.uuid4()
s = str(u)
pattern = r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
assert re.match(pattern, s), f'UUID string format invalid: {s}'
print('UUID string:', s)
print('String format: OK')
"

echo "Test 6: UUID from string roundtrip"
python3.12 -c "
import fastuuid
original = fastuuid.uuid4()
parsed = fastuuid.UUID(str(original))
assert original == parsed, f'Roundtrip mismatch: {original} != {parsed}'
print('Roundtrip:', original, '->', parsed)
print('String roundtrip: OK')
"

echo "Test 7: UUID bytes roundtrip"
python3.12 -c "
import fastuuid
original = fastuuid.uuid4()
parsed = fastuuid.UUID(bytes=original.bytes)
assert original == parsed, f'Bytes roundtrip mismatch: {original} != {parsed}'
assert len(original.bytes) == 16, f'Expected 16 bytes, got {len(original.bytes)}'
print('Bytes roundtrip:', original)
print('Bytes roundtrip: OK')
"

echo "Test 8: UUID int roundtrip"
python3.12 -c "
import fastuuid
original = fastuuid.uuid4()
parsed = fastuuid.UUID(int=original.int)
assert original == parsed, f'Int roundtrip mismatch: {original} != {parsed}'
print('Int roundtrip:', original.int)
print('Int roundtrip: OK')
"

echo "Test 9: UUID fields"
python3.12 -c "
import fastuuid
u = fastuuid.uuid4()
assert hasattr(u, 'time_low'), 'Missing field: time_low'
assert hasattr(u, 'time_mid'), 'Missing field: time_mid'
assert hasattr(u, 'time_hi_version'), 'Missing field: time_hi_version'
assert hasattr(u, 'clock_seq_hi_variant'), 'Missing field: clock_seq_hi_variant'
assert hasattr(u, 'clock_seq_low'), 'Missing field: clock_seq_low'
assert hasattr(u, 'node'), 'Missing field: node'
print('Fields:', u.fields)
print('UUID fields: OK')
"

echo "Test 10: Comparison and hashing"
python3.12 -c "
import fastuuid
a = fastuuid.uuid4()
b = fastuuid.uuid4()
same = fastuuid.UUID(str(a))
assert a == same, 'Equality failed for same UUID'
assert a != b, 'Two random UUIDs should not be equal'
assert hash(a) == hash(same), 'Hash mismatch for equal UUIDs'
s = {a, b, same}
assert len(s) == 2, f'Set deduplication failed: expected 2 elements, got {len(s)}'
print('Comparison and hashing: OK')
"

echo -e "\n=== Build Complete ==="
echo "Wheel: $WHEEL"