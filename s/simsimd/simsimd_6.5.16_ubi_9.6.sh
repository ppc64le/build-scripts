#!/bin/bash -e
# ----------------------------------------------------------------------------
# Package          : simsimd
# Version          : v6.5.16
# Source repo      : https://github.com/ashvardanian/NumKong.git
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

PACKAGE_DIR="NumKong"
PACKAGE_NAME="simsimd"
PACKAGE_VERSION=${1:-v6.5.16}
PACKAGE_URL="https://github.com/ashvardanian/NumKong.git"
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
echo "Test 2: Capabilities"
python3.12 -c "
import simsimd
caps = simsimd.get_capabilities()
assert isinstance(caps, dict), 'get_capabilities must return a dict'
assert 'serial' in caps, 'serial key must be present'
print('Capabilities:', caps)
print('Capabilities: OK')
"

echo "Test 3: One-to-one distances (float32)"
python3.12 -c "
import simsimd
from array import array
import math

a = array('f', [float(i) / 256 for i in range(256)])
b = array('f', [float(256 - i) / 256 for i in range(256)])

cos = simsimd.cosine(a, b)
assert 0.0 <= float(cos) <= 2.0, f'cosine out of range: {cos}'

sqe = simsimd.sqeuclidean(a, b)
assert float(sqe) >= 0.0, f'sqeuclidean negative: {sqe}'

ip = simsimd.inner(a, b)
assert math.isfinite(float(ip)), f'inner not finite: {ip}'

print(f'  cosine={cos:.6f}  sqeuclidean={sqe:.6f}  inner={ip:.6f}')
print('One-to-one distances (float32): OK')
"

echo "Test 4: One-to-one distances (int8)"
python3.12 -c "
import simsimd
from array import array
import math

a = array('b', [(i % 127) for i in range(128)])
b = array('b', [(127 - i % 127) for i in range(128)])

cos = simsimd.cosine(a, b, 'int8')
sqe = simsimd.sqeuclidean(a, b, 'int8')
assert math.isfinite(float(cos)), f'cosine not finite: {cos}'
assert float(sqe) >= 0.0, f'sqeuclidean negative: {sqe}'

print(f'  cosine={cos:.6f}  sqeuclidean={sqe:.6f}')
print('One-to-one distances (int8): OK')
"

echo "Test 5: Binary distances (hamming, jaccard)"
python3.12 -c "
import simsimd
from array import array

v = array('B', [0b10101010] * 32)
assert simsimd.hamming(v, v, 'bin8') == 0.0, 'hamming of identical vectors must be 0'
assert simsimd.jaccard(v, v, 'bin8') == 0.0, 'jaccard of identical vectors must be 0'

z = array('B', [0x00] * 32)
o = array('B', [0xFF] * 32)
assert simsimd.hamming(z, o, 'bin8') == 256.0, 'hamming(zeros, ones) must equal bit-length'

print('Binary distances (hamming, jaccard): OK')
"

echo "Test 6: One-to-many distances"
python3.12 -c "
import simsimd
from array import array

query  = array('f', [float(i) / 128 for i in range(128)])
matrix = [array('f', [float((i + j) % 128) / 128 for i in range(128)]) for j in range(50)]

dists = [float(simsimd.cosine(query, row)) for row in matrix]
assert len(dists) == 50, f'expected 50 distances, got {len(dists)}'
assert all(0.0 <= d <= 2.0 for d in dists), 'cosine distances must be in [0, 2]'

print(f'  computed {len(dists)} distances, min={min(dists):.4f} max={max(dists):.4f}')
print('One-to-many distances: OK')
"

echo "Test 7: Probability divergences (float32)"
python3.12 -c "
import simsimd
from array import array
import math

total = 64
p_raw = [float(i + 1) for i in range(total)]
q_raw = [float(total - i) for i in range(total)]
p_sum = sum(p_raw)
q_sum = sum(q_raw)
p = array('f', [x / p_sum for x in p_raw])
q = array('f', [x / q_sum for x in q_raw])

kl = simsimd.kullbackleibler(p, q)
js = simsimd.jensenshannon(p, q)
assert float(kl) >= 0, f'KL divergence must be non-negative: {kl}'
assert 0 <= float(js) <= 1, f'JS divergence must be in [0, 1]: {js}'

print(f'  kl={kl:.6f}  js={js:.6f}')
print('Probability divergences (float32): OK')
"

echo "Test 8: cdist (all-pairs)"
python3.12 -c "
import simsimd
from simsimd import cdist, DistancesTensor
from array import array
import ctypes

rows1 = [[float((i + j) % 64) / 64 for i in range(64)] for j in range(20)]
rows2 = [[float((i * j + 1) % 64) / 64 for i in range(64)] for j in range(10)]

flat1 = array('f', [v for row in rows1 for v in row])
flat2 = array('f', [v for row in rows2 for v in row])

try:
    import numpy as np
    m1 = np.frombuffer(flat1, dtype=np.float32).reshape(20, 64)
    m2 = np.frombuffer(flat2, dtype=np.float32).reshape(10, 64)
    dt = cdist(m1, m2, metric='cosine')
    assert isinstance(dt, DistancesTensor), 'cdist must return DistancesTensor'
    arr = np.array(dt, copy=True)
    assert arr.shape == (20, 10), f'expected shape (20, 10), got {arr.shape}'
    print(f'  shape={arr.shape}  min={arr.min():.4f}  max={arr.max():.4f}')
    print('cdist (all-pairs): OK')
except ImportError:
    print('cdist (all-pairs): SKIPPED (numpy not available for 2D reshape)')
"

echo -e "\n=== Build Complete ==="
echo "Wheel: $WHEEL"