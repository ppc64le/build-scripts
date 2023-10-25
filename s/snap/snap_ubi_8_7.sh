#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : snap
# Version       : v2.0.3
# Source repo   : https://github.com/amplab/snap
# Tested on     : UBI: 8.7
# Language      : c++
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e
PACKAGE_NAME=snap
PACKAGE_URL=https://github.com/amplab/snap

# Default tag snap
if [ -z "$1" ]; then
  export PACKAGE_VERSION="v2.0.3"
else
  export PACKAGE_VERSION="$1"
fi


# install tools and dependent packages
yum install -y git gcc gcc-c++ make glibc-devel pkgconfig autoconf automake libtool git cmake zlib-devel

# Cloning the repository 
git clone $PACKAGE_URL 
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

sed -i '/-msse/c\CXXFLAGS += -MMD -ISNAPLib  -DNO_WARN_X86_INTRINSICS -mcpu=powerpc64le -mtune=powerpc64le' Makefile
sed -i '0,/\bunit_tests\b/{/\bunit_tests\b/s/\bunit_tests\b//}' Makefile
sed -i '/__linux__/a\#include <emmintrin.h>' SNAPLib/Compat.h

#building snap
if ! make; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
elif ! make unit_tests; then
    echo "------------------$PACKAGE_NAME:test_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 0
fi
