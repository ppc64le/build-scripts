#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : matplotlib
# Version       : v3.11.0
# Source repo   : https://github.com/matplotlib/matplotlib.git
# Tested on     : UBI:10.2
# Language      : Python, C++, Jupyter Notebook
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Yogita Kulkarni <yogita.kulkarni@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_DIR="matplotlib"
PACKAGE_NAME="matplotlib"
PACKAGE_VERSION=${1:-v3.11.0}
PACKAGE_URL="https://github.com/matplotlib/matplotlib.git"
CURRENT_DIR="$(pwd)"
echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"

# -- System dependencies ------------------------------------------------------
dnf install -y \
    gcc-toolset-15 \
    git \
    python3.14 \
    python3.14-devel \
    python3.14-pip \
    libjpeg-turbo-devel \
    zlib-devel \
    libpng-devel \
    freetype-devel \
    lcms2-devel \
    libtiff-devel \
    libwebp-devel \
    openjpeg2-devel

if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:${LD_LIBRARY_PATH:-}"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi
gcc --version

# Compiler hints - help Pillow's setup.py locate system image headers
export CFLAGS="-I/usr/include"
export LDFLAGS="-L/usr/lib64"

python3.14 -m pip install --upgrade pip wheel build setuptools

# Clone and checkout
rm -rf "$PACKAGE_DIR"
git clone "$PACKAGE_URL"
cd "$PACKAGE_DIR"
git checkout "$PACKAGE_VERSION"
git submodule update --init --depth 1

# -- Build wheel --------------------------------------------------------------
DIST_DIR="${CURRENT_DIR}/dist"
[ "$CURRENT_DIR" = "/" ] && DIST_DIR="/dist"
mkdir -p "$DIST_DIR"
python3.14 -m build --wheel --outdir "$DIST_DIR"

WHEEL=$(find "$DIST_DIR" -name "${PACKAGE_NAME}-*.whl" | head -1)
if [ -z "$WHEEL" ]; then
    echo "ERROR: wheel not found after build"
    exit 1
fi
echo "Wheel: $WHEEL"

# -- Install ------------------------------------------------------------------
cd "$CURRENT_DIR"
# Pre-install numpy so pip does not build it from source as a dependency
python3.14 -m pip install numpy==2.5.0
# Force-reinstall to ensure any previously installed matplotlib is replaced
python3.14 -m pip install --force-reinstall "$WHEEL"

# -- Tests --------------------------------------------------------------------
cd /tmp
python3.14 - << 'PYEOF'
import sys

# 1. Import and version check
import matplotlib
assert matplotlib.__version__ == "3.11.0", f"Unexpected version: {matplotlib.__version__}"
print(f"PASS  import matplotlib {matplotlib.__version__}")

# 2. C extension sanity check
import matplotlib._c_internal_utils
print("PASS  C extension loaded")

# 3. Headless render - no display required
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import io

fig, ax = plt.subplots()
ax.plot(np.linspace(0, 2 * np.pi, 100), np.sin(np.linspace(0, 2 * np.pi, 100)))
ax.set_title("smoke test")
buf = io.BytesIO()
fig.savefig(buf, format="png")
plt.close(fig)
assert buf.tell() > 0
print("PASS  headless PNG render")

# 4. Key sub-packages importable
import matplotlib.pyplot
import matplotlib.patches
import matplotlib.colors
import matplotlib.ticker
import matplotlib.dates
print("PASS  key sub-packages importable")

print("\nAll tests passed.")
sys.exit(0)
PYEOF

if [ $? -ne 0 ]; then
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
