#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : re2
# Version       : 2022-04-01
# Source repo   : https://github.com/google/re2.git
# Tested on     : UBI 10.2
# Language      : c
# Ci-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Sakshi Jain <sakshi.jain16@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e 

PACKAGE_NAME=re2
PACKAGE_VERSION=${1:-2022-04-01}
PACKAGE_URL=https://github.com/google/re2.git
CURRENT_DIR=$(pwd)
PACKAGE_DIR=re2

echo "------------------------Installing dependencies-------------------"
yum install -y wget

# install core dependencies
yum install -y python3.14 python3.14-pip python3.14-devel gcc gcc-c++ git make cmake binutils

gcc --version

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

python3.14 -m pip install --upgrade pip setuptools wheel build ninja

export CC=$(which gcc)
export CXX=$(which g++)
export GCC=$CC
export GXX=$CXX

# clone source repository
cd $CURRENT_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init --recursive


wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/r/re2/pyproject.toml
sed -i "s/{PACKAGE_VERSION}/$(echo $PACKAGE_VERSION | tr -d '-')/g" pyproject.toml
echo "--------------------------replaced version in pyproject.toml--------------------------"

mkdir -p prefix
export PREFIX=$(pwd)/prefix

export CPU_COUNT=`nproc`

mkdir -p build-cmake
cd build-cmake

cmake ${CMAKE_ARGS} -GNinja \
  -DCMAKE_PREFIX_PATH=$PREFIX \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DENABLE_TESTING=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  ..

ninja -v install
cd ..

#Build package
if ! (make -j "${CPU_COUNT}" prefix=${PREFIX} shared-install) ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

mkdir -p local/$PACKAGE_NAME
cp -r $CURRENT_DIR/$PACKAGE_NAME/prefix/* local/$PACKAGE_NAME/

#During wheel creation for this package we need exported cmake-args. Once script get exit, and if we build wheel through wrapper script, then those are not applicable during wheel creation. So we are generating wheel for this package in script itself.
echo "---------------------------------------------------Building the wheel--------------------------------------------------"
python3.14 -m pip install --upgrade pip build setuptools wheel
python3.14 -m build --wheel --no-isolation --outdir="$CURRENT_DIR/"

echo "----------------------------------------------Testing pkg-------------------------------------------------------"
#Test package
if ! (make test) ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi