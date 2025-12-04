#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : zlib
# Version       : v1.3.1
# Source repo   : https://github.com/madler/zlib
# Tested on     : UBI 9.3 (ppc64le)
# Language      : C
# Ci-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=zlib
PACKAGE_VERSION=${1:-v1.3.1}
PACKAGE_URL=https://github.com/madler/zlib.git
BUILD_HOME="$(pwd)"

# Install required dependencies
yum install -y git gcc make autoconf

# Clone and checkout specified version
cd $BUILD_HOME
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Build the package
ret=0
./configure 
make -j$(nproc) || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "echo------------------ ${PACKAGE_NAME}: Build Failed ------------------"
    exit 1
fi

#  Installs the compiled binaries and headers to the system directories
make install || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "echo------------------ ${PACKAGE_NAME}: Installation Failed -----------"
    exit 1
fi

# Test the package
make check || ret=$?
if [ "$ret" -ne 0 ]; then
	echo "echo------------------ ${PACKAGE_NAME}: Test Failed -----------"
    exit 2
fi

echo "SUCCESS: ${PACKAGE_NAME}_${PACKAGE_VERSION} build and test completed successfully!"
