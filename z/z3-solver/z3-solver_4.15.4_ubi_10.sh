#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : z3-solver
# Version       : z3-4.15.4
# Source repo   : https://github.com/Z3Prover/z3
# Tested on     : UBI:10.2
# Language      : Python
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

set -e

PACKAGE_NAME=z3-solver
PACKAGE_VERSION=${1:-z3-4.15.4}
PACKAGE_URL=https://github.com/Z3Prover/z3
PACKAGE_DIR=z3
CURRENT_DIR=$(pwd)

# Install dependencies
yum install -y python3.12 python3.12-devel python3.12-pip \
    git gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    make

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

# Install Python build tools
pip install --upgrade pip setuptools wheel build

# Clone repository
cd $CURRENT_DIR
rm -rf $PACKAGE_DIR
git clone $PACKAGE_URL $PACKAGE_DIR
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

# Patch src/api/python/setup.py for ppc64le wheel tag
python3.12 - <<'PYEOF'
from pathlib import Path
p = Path("src/api/python/setup.py")
src = p.read_text()
entry = "    ('linux', 'ppc64le'): 'manylinux2014_ppc64le',\n"
if entry in src:
    print("  setup.py already patched — skipping")
elif "TAGS = {" in src:
    p.write_text(src.replace("TAGS = {", "TAGS = {\n" + entry, 1))
    print("  setup.py patched OK")
else:
    raise SystemExit("Could not find TAGS dict in setup.py")
PYEOF

# Build Z3 native library using the bundled mk_make.py build system
# Do NOT pass --python/--pypkgdir here: mk_make.py requires --pypkgdir to live
# under --prefix (/usr), which a source-relative path never satisfies.
# The Python wheel is built separately via setup.py below.
python3.12 scripts/mk_make.py
cd build
make -j"$(nproc)"
make install

# Build and install the Python bindings wheel
cd $CURRENT_DIR/$PACKAGE_DIR/src/api/python

# Install package
if ! python3.12 setup.py install ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Copy wheel to CURRENT_DIR
python3.12 setup.py bdist_wheel
cp dist/*.whl $CURRENT_DIR/

# Run tests
cd $CURRENT_DIR/$PACKAGE_DIR
if ! python3.12 -c "import z3; s = z3.Solver(); x = z3.Int('x'); s.add(x > 0); assert str(s.check()) == 'sat'; print('z3 basic smoke test passed')" ; then
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
