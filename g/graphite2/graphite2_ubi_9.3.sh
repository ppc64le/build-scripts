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

# Install dependencies and tools.
# cmake is required to build the native libgraphite2.so.3 shared library,
# which the Python ctypes bindings load at import time.
yum install -y wget gcc gcc-c++ gcc-gfortran git make cmake python3-devel openssl-devel

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

# Install the Python ctypes bindings.
if ! python3 setup.py install ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Verify the import succeeds (ctypes must find libgraphite2.so.3 at runtime).
if ! python3 -c "import graphite2; print('graphite2 import successful')" ; then
    echo "------------------$PACKAGE_NAME:Import_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Import_Fails"
    exit 1
fi

echo "------------------$PACKAGE_NAME:Install_and_Import_success-------------------------"
echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass |  Both"