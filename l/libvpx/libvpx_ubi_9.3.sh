#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : libvpx
# Version       : 1.3.1
# Source repo   : https://github.com/webmproject/libvpx
# Tested on     : UBI:9.3
# Language      : Python, C
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=libvpx
PACKAGE_DIR=libvpx
PACKAGE_VERSION=${1:-v1.13.1}
PACKAGE_URL=https://github.com/webmproject/libvpx

# install core dependencies
yum install -y python python-pip python-devel git cmake gcc-toolset-13 wget
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH

# clone source repository
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

mkdir prefix
export PREFIX=$(pwd)/prefix

export target_platform=$(uname)-$(uname -m)
export CC=$(which gcc)
export CXX=$(which g++)

# Get an updated config.sub and config.guess
#cp $BUILD_PREFIX/share/libtool/build-aux/config.* .


if [[ ${target_platform} == Linux-* ]]; then
    LDFLAGS="$LDFLAGS -pthread"
fi

CPU_DETECT="${CPU_DETECT} --enable-runtime-cpu-detect"

./configure --prefix=$PREFIX $HOST_BUILD \
--as=yasm                    \
--enable-shared              \
--disable-static             \
--disable-install-docs       \
--disable-install-srcs       \
--enable-vp8                 \
--enable-postproc            \
--enable-vp9                 \
--enable-vp9-highbitdepth    \
--enable-pic                 \
${CPU_DETECT}                \
--enable-experimental || { cat config.log; exit 1; }
make -j${CPU_COUNT}
make install


mkdir -p local/libvpx
cp -r prefix/* local/libvpx/

pip install setuptools

#dDownloading pyproject.toml file
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/l/libvpx/pyproject.toml
sed -i s/{PACKAGE_VERSION}/$PACKAGE_VERSION/g pyproject.toml

if ! pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:Install_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_Success"
    exit 0
fi

echo "There are no test cases available. skipping the test cases"
