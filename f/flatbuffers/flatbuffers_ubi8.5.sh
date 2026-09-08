#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: flatbuffers
# Version	: v1.12.0
# Source repo	: https://github.com/google/flatbuffers
# Tested on	: UBI 8.5
# Language      : C++/CLANG
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: BulkPackageSearch Automation {maintainer}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="flatbuffers"
PACKAGE_VERSION=${1:-v1.12.0}
PACKAGE_URL="https://github.com/google/flatbuffers"

yum update -y && yum install -y git clang cmake make

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

if ! git clone --branch ${PACKAGE_VERSION} ${PACKAGE_URL}; then
	echo "------------------$PACKAGE_NAME:clone failed-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $PACKAGE_VERSION | $OS_NAME | GitHub  | Failed |  Clone failed"
        exit 1
fi

HOME_DIR=`pwd`
cd "$HOME_DIR/$PACKAGE_NAME"

# Build
echo "Building $PACKAGE_PATH with $PACKAGE_VERSION"
if ! [[ $(cmake -G 'Unix Makefiles' -DCMAKE_BUILD_TYPE=Release) && $(make -j4) ]]; then
	echo "------------------$PACKAGE_NAME:Build failed-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $PACKAGE_VERSION | $OS_NAME | GitHub  | Failed |  Build failed"
	exit 1
fi

echo "Testing $PACKAGE_PATH with $PACKAGE_VERSION"

# Test and install
if ! [[ $(./flattests) && $(make install) ]]; then
	echo "------------------$PACKAGE_NAME:install_&_test_failed-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $PACKAGE_VERSION | $OS_NAME | GitHub  | Failed |  Test failed"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi
