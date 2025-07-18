#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : opus
# Version       : 1.3.1
# Source repo   : https://github.com/xiph/opus
# Tested on     : UBI:9.3
# Language      : Python, C
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=opus
PACKAGE_DIR=opus
PACKAGE_VERSION=${1:-v1.3.1}
PACKAGE_URL=https://github.com/xiph/opus

# install core dependencies
yum install -y git cmake gcc-toolset-13 autoconf automake libtool wget
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH

# clone source repository
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

mkdir prefix
export PREFIX=$(pwd)/prefix

if [[ $(uname) == MSYS* ]]; then
  if [[ ${ARCH} == 32 ]]; then
    HOST_BUILD="--host=i686-w64-mingw32 --build=i686-w64-mingw32"
  else
    HOST_BUILD="--host=x86_64-w64-mingw32 --build=x86_64-w64-mingw32"
  fi
  PREFIX=${PREFIX}/Library/mingw-w64
  JOBS=${NUMBER_OF_PROCESSORS}
elif [[ $(uname) == Darwin ]]; then
  JOBS=$(sysctl -n hw.ncpu)
else
  JOBS=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1)
fi

./autogen.sh
./configure --prefix=$PREFIX $HOST_BUILD && make -j$JOBS && make install

#test
make check

if [ $? == 0 ]; then
    echo "------------------$PACKAGE_NAME:Install_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_Success"
    exit 0
fi
