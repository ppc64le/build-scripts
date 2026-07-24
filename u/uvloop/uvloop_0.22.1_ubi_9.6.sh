#!/bin/bash -e
# ----------------------------------------------------------------------------
# Package          : uvloop
# Version          : v0.22.1
# Source repo      : https://github.com/MagicStack/uvloop.git
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

PACKAGE_DIR="uvloop"
PACKAGE_NAME="uvloop"
PACKAGE_VERSION=${1:-v0.22.1}
PACKAGE_URL="https://github.com/MagicStack/uvloop.git"
SOURCE_ROOT="$(pwd)"

echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"

# Install system dependencies
dnf install -y gcc-toolset-13 git \
    python3.12 python3.12-devel python3.12-pip \
    autoconf automake libtool

export PATH="/opt/rh/gcc-toolset-13/root/usr/bin:$PATH"
export CFLAGS="-I/usr/include"
export LDFLAGS="-L/usr/lib64"

# Install build dependencies
# Use earlier setuptools version to include pkg_resources
python3.12 -m pip install --upgrade pip "setuptools>=60,<72" wheel "cython~=3.1" build

# Clone and checkout
rm -rf "$PACKAGE_DIR"
git clone "$PACKAGE_URL"
cd "${PACKAGE_DIR}"
git checkout "$PACKAGE_VERSION"
git submodule update --init --depth 1

# Build wheel — no isolation since deps are already installed above
python3.12 -m build --wheel --no-isolation --outdir "${SOURCE_ROOT}/dist/"

WHEEL=$(find "${SOURCE_ROOT}/dist" -name "${PACKAGE_NAME}-*.whl" | head -1)
if [ -z "$WHEEL" ]; then
    echo "ERROR: wheel not found after build"
    exit 1
fi
echo "Wheel: $WHEEL"

cd "${SOURCE_ROOT}"

cp "${WHEEL}" "${SOURCE_ROOT}"

# Install wheel
echo "=== Installing Wheel ==="
python3.12 -m pip install "$WHEEL"

# Run tests
echo "=== Running Tests ==="
TESTS_PASSED=0
TESTS_FAILED=0

# Test 1: Import and version
echo "Test 1: Import and version"
python3.12 -c "
import uvloop
from importlib.metadata import version
v = version('uvloop')
assert v, 'Version string is empty'
print('  version:', v)
print('  file:', uvloop.__file__)
print('  PASSED')
" && TESTS_PASSED=$((TESTS_PASSED+1)) || { echo "  FAILED"; TESTS_FAILED=$((TESTS_FAILED+1)); }

# Test 2: Event loop policy installs and restores correctly
echo "Test 2: Event loop policy"
python3.12 -c "
import asyncio
import uvloop
uvloop.install()
policy = asyncio.get_event_loop_policy()
assert isinstance(policy, uvloop.EventLoopPolicy), \
    'Expected uvloop.EventLoopPolicy, got {}'.format(type(policy))
print('  policy:', type(policy).__name__)
print('  PASSED')
" && TESTS_PASSED=$((TESTS_PASSED+1)) || { echo "  FAILED"; TESTS_FAILED=$((TESTS_FAILED+1)); }

# Test 3: Event loop is a uvloop instance
echo "Test 3: Event loop type"
python3.12 -c "
import asyncio
import uvloop
uvloop.install()
loop = asyncio.new_event_loop()
assert isinstance(loop, uvloop.Loop), \
    'Expected uvloop.Loop, got {}'.format(type(loop))
loop.close()
print('  loop type:', type(loop).__name__)
print('  PASSED')
" && TESTS_PASSED=$((TESTS_PASSED+1)) || { echo "  FAILED"; TESTS_FAILED=$((TESTS_FAILED+1)); }

# Test 4: Run a basic coroutine
echo "Test 4: Run coroutine"
python3.12 -c "
import uvloop

async def add(a, b):
    return a + b

result = uvloop.run(add(2, 3))
assert result == 5, 'Expected 5, got {}'.format(result)
print('  result:', result)
print('  PASSED')
" && TESTS_PASSED=$((TESTS_PASSED+1)) || { echo "  FAILED"; TESTS_FAILED=$((TESTS_FAILED+1)); }

# Test 5: Asyncio sleep works inside uvloop
echo "Test 5: Async sleep"
python3.12 -c "
import asyncio
import uvloop
import time

async def timed_sleep():
    start = time.monotonic()
    await asyncio.sleep(0.05)
    return time.monotonic() - start

elapsed = uvloop.run(timed_sleep())
assert elapsed >= 0.05, 'Sleep returned too early: {}s'.format(elapsed)
print('  elapsed: {:.3f}s'.format(elapsed))
print('  PASSED')
" && TESTS_PASSED=$((TESTS_PASSED+1)) || { echo "  FAILED"; TESTS_FAILED=$((TESTS_FAILED+1)); }

# Test 6: TCP echo server and client
echo "Test 6: TCP echo server/client"
python3.12 -c "
import asyncio
import uvloop

RESPONSE = b''

async def handle(reader, writer):
    data = await reader.read(100)
    writer.write(data)
    await writer.drain()
    writer.close()

async def run():
    global RESPONSE
    server = await asyncio.start_server(handle, '127.0.0.1', 0)
    port = server.sockets[0].getsockname()[1]
    reader, writer = await asyncio.open_connection('127.0.0.1', port)
    writer.write(b'hello')
    await writer.drain()
    RESPONSE = await reader.read(100)
    writer.close()
    server.close()
    await server.wait_closed()

uvloop.run(run())
assert RESPONSE == b'hello', 'Expected b\"hello\", got {}'.format(RESPONSE)
print('  echo response:', RESPONSE)
print('  PASSED')
" && TESTS_PASSED=$((TESTS_PASSED+1)) || { echo "  FAILED"; TESTS_FAILED=$((TESTS_FAILED+1)); }

# Test 7: Gather runs tasks concurrently
echo "Test 7: Concurrent tasks with gather"
python3.12 -c "
import asyncio
import uvloop
import time

async def task(n):
    await asyncio.sleep(0.05)
    return n * 2

async def run():
    start = time.monotonic()
    results = await asyncio.gather(task(1), task(2), task(3))
    elapsed = time.monotonic() - start
    return results, elapsed

results, elapsed = uvloop.run(run())
assert results == [2, 4, 6], 'Expected [2, 4, 6], got {}'.format(results)
# All three 50ms sleeps should complete in roughly 50ms, not 150ms
assert elapsed < 0.2, 'Tasks did not run concurrently: {:.3f}s'.format(elapsed)
print('  results:', results)
print('  elapsed: {:.3f}s'.format(elapsed))
print('  PASSED')
" && TESTS_PASSED=$((TESTS_PASSED+1)) || { echo "  FAILED"; TESTS_FAILED=$((TESTS_FAILED+1)); }

# Summary
echo ""
echo "=== Test Summary ==="
echo "  Passed: ${TESTS_PASSED}"
echo "  Failed: ${TESTS_FAILED}"
if [ "$TESTS_FAILED" -gt 0 ]; then
    echo "  RESULT: FAILED"
    exit 1
fi
echo "  RESULT: ALL TESTS PASSED"

echo -e "\n=== Build Complete ==="
echo "Wheel: $WHEEL"