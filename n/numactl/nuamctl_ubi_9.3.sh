#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : numactl
# Version       : v2.0.19
# Source repo   : https://github.com/numactl/numactl
# Tested on     : UBI 9.3
# Language      : C
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Balavva Mirji <Balavva.Mirji@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such cases, please
#             contact the "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=numactl
PACKAGE_VERSION=${1:-v2.0.19}
PACKAGE_URL=https://github.com/numactl/numactl

# Install dependencies
yum install -y git autoconf automake libtool

# Clone the repository
git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME

# Checkout the specified version
git checkout $PACKAGE_VERSION

# Prepare the build system
./autogen.sh
./configure

# Compile the package
if ! make; then
    echo "------------------$PACKAGE_NAME: Build failed ------------------"
    exit 1
fi

# Install the package
if ! make install; then
    echo "------------------$PACKAGE_NAME: Install failed ------------------"
    exit 1
else
    echo "------------------$PACKAGE_NAME: Install success ------------------"
fi

# Run the unit test case 
if ! make -k check VERBOSE=1 TESTS='test/tbitmap'; then
    echo "------------------$PACKAGE_NAME: Test tbitmap failed ------------------"
    exit 2
else
    echo "------------------$PACKAGE_NAME: Test tbitmap passed ------------------"
fi

# Verify installation
if ! numactl --version; then
    echo "------------------$PACKAGE_NAME: Version check failed ------------------"
    exit 1
else
    echo "------------------$PACKAGE_NAME: Installed successfully ------------------"
    exit 0
fi