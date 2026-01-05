#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : p7zip
# Version       : v17.05
# Source repo   : https://github.com/p7zip-project/p7zip
# Tested on     : UBI 9.3 (ppc64le)
# Language      : ASM, C, C++
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

PACKAGE_NAME=p7zip
PACKAGE_VERSION=${1:-v17.05}
PACKAGE_URL=https://github.com/${PACKAGE_NAME}-project/p7zip.git
BUILD_HOME=$(pwd)

# Install required libraries
yum install -y git gcc gcc-c++ make diffutils cmake autoconf automake libtool binutils glibc-devel xz-devel zlib-devel  

# Clone the repository
cd $BUILD_HOME
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Build the project
ret=0
make -j $(nproc) || ret=$?
if [ "$ret" -ne 0 ]
then
	exit 1
fi

# Verify build, if the file exists and is executable
P7ZIP_BIN="$BUILD_HOME/$PACKAGE_NAME/bin/7za"
if [ ! -x "$P7ZIP_BIN" ]; then
	echo "Build verification failed: $P7ZIP_BIN not found or not executable."
 	exit 1
fi

#Run Test
make test || ret=$?
if [ "$ret" -ne 0 ]
then
	echo "FAIL: Tests failed."
	exit 2
fi

# Smoke test
# Extract version from command output
EXTRACTED_VERSION=$("$P7ZIP_BIN" | head -n 2 | awk '{print $3}' | tr -d '[:space:]')
BASE_VERSION=${PACKAGE_VERSION#v}  # Removing 'v' prefix

#verify
if [[ "$EXTRACTED_VERSION" == "$BASE_VERSION" ]]; then
    echo "SUCCESS: Build and smoke test passed!"
    echo "$PACKAGE_NAME binary is available at [ $P7ZIP_BIN ] with version [$PACKAGE_VERSION]."
else
    echo "FAIL: Expected version [$BASE_VERSION] but got [$EXTRACTED_VERSION]."
    exit 2
fi
