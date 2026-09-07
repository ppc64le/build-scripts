#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : graphite2
# Version       : 1.3.14
# Source repo   : https://github.com/silnrsi/graphite
# Tested on     : UBI:9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#variables
PACKAGE_NAME=graphite2
PACKAGE_VERSION=${1:-1.3.14}
PACKAGE_URL=https://github.com/silnrsi/graphite
CURRENT_DIR=$(pwd)

# Install dependencies and tools.
# cmake is required to build the native libgraphite2.so.3 shared library,
# which the Python ctypes bindings load at import time.
yum install -y wget gcc gcc-c++ gcc-gfortran git make cmake python3-devel openssl-devel python3-pip

#clone repository
git clone $PACKAGE_URL
cd graphite
git checkout $PACKAGE_VERSION

# Build and install the native shared library (libgraphite2.so.3).
# The Python package is a pure ctypes wrapper; it has no compiled extension
# of its own and will fail to import with:
#   OSError: libgraphite2.so.3: cannot open shared object file: No such file or directory
# unless the shared library is present on the system ld path first.
mkdir -p build_cmake
cd build_cmake
cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF
make -j"$(nproc)"
make install
cd ..

# /usr/local/lib is not in the default ldconfig search path on UBI 9.
# Register it explicitly so libgraphite2.so.3 is discoverable at runtime.
echo "/usr/local/lib" > /etc/ld.so.conf.d/graphite2.conf
ldconfig

# Stage libgraphite2.so.3 into python/graphite2/lib/ — the bundled library
# the wheel carries for self-contained use on any Power device.
# Copy the real file for all three names (no symlinks) so the wheel zip
# contains actual files that extract correctly on any target container.
mkdir -p python/graphite2/lib
cp build_cmake/src/libgraphite2.so.3.2.1 python/graphite2/lib/libgraphite2.so.3.2.1
cp build_cmake/src/libgraphite2.so.3.2.1 python/graphite2/lib/libgraphite2.so.3
cp build_cmake/src/libgraphite2.so.3.2.1 python/graphite2/lib/libgraphite2.so

# Patch __init__.py so the wheel's own lib/ is checked FIRST, before
# ctypes.util.find_library() is called.  Without this patch, find_library()
# can return a bare SONAME ("libgraphite2.so.3") on a system that has no
# graphite2 installed, which is not None, so the wheel fallback is skipped
# and LoadLibrary() fails with "No such file or directory".
# Use a Python one-liner to do the replacement so indentation is exact.
python3 - <<'PYEOF'
import pathlib

init = pathlib.Path("python/graphite2/__init__.py")
src  = init.read_text()

old = (
    "libpath = os.environ.get('PYGRAPHITE2_LIBRARY_PATH',\n"
    "                         ctypes.util.find_library(\"graphite2\"))\n"
    "if libpath is None:\n"
    "    # find wheel's library\n"
    "    wheel = os.path.dirname(__file__)\n"
    "    if os.name == 'nt':\n"
    "        libpath = os.path.join(wheel, 'bin', 'graphite2.dll')\n"
    "    else:\n"
    "        libpath = os.path.join(wheel, 'lib', 'libgraphite2.so')"
)

new = (
    "# Always prefer the library bundled inside the wheel so the wheel is\n"
    "# self-contained.  Only fall back to the system library when the wheel\n"
    "# carries no bundled copy (e.g. a plain source install).\n"
    "_wheel_lib = os.path.join(os.path.dirname(__file__), 'lib', 'libgraphite2.so')\n"
    "if os.path.exists(_wheel_lib):\n"
    "    libpath = _wheel_lib\n"
    "else:\n"
    "    libpath = os.environ.get('PYGRAPHITE2_LIBRARY_PATH',\n"
    "                             ctypes.util.find_library('graphite2'))"
)

if "_wheel_lib" not in src:
    src = src.replace(old, new)
    init.write_text(src)
    print("__init__.py patched")
else:
    print("__init__.py already patched, skipping")
PYEOF

# Patch setup.py to declare the staged .so files as package_data so that
# bdist_wheel includes them inside the wheel archive.
sed -i "s|    packages         = \['graphite2'\],|    packages         = ['graphite2'],\n    package_data     = {'graphite2': ['lib/libgraphite2.so*']},|" setup.py

# Build the wheel — graphite2/lib/libgraphite2.so* is now included.
pip3 install wheel
mkdir -p dist
python3 setup.py bdist_wheel --dist-dir "$CURRENT_DIR/"

WHEEL_FILE=$(ls "$CURRENT_DIR"/graphite2-*.whl | head -1)
echo "Arch-specific self-contained wheel: $WHEEL_FILE"

# Install from the wheel.
if ! pip3 install "$WHEEL_FILE" ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Verify the import succeeds.
if ! python3 -c "import graphite2; print('graphite2 import successful')" ; then
    echo "------------------$PACKAGE_NAME:Import_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Import_Fails"
    exit 1
fi

echo "------------------$PACKAGE_NAME:Install_and_Import_success-------------------------"
echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass |  Both"