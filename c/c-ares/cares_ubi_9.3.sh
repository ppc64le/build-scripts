#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : c-ares
# Version       : cares-1_19_1
# Source repo   : https://github.com/c-ares/c-ares.git
# Tested on     : UBI 9.3
# Language      : c
# Ci-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e 

PACKAGE_NAME=c-ares
PACKAGE_VERSION=${1:-cares-1_19_1}
PACKAGE_URL=https://github.com/c-ares/c-ares.git
CURRENT_DIR=$(pwd)
PACKAGE_DIR=c-ares


echo "------------------------Installing dependencies-------------------"
yum install -y wget

# install core dependencies
yum install -y python python-pip python-devel  gcc-toolset-13 gcc-toolset-13-binutils gcc-toolset-13-binutils-devel gcc-toolset-13-gcc-c++ git make cmake binutils

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
gcc --version

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

target_platform=$(uname)-$(uname -m)
AR=$(which ar)


# install dependency
python -m pip install --upgrade pip
pip install setuptools ninja build wheel

# clone source repository
cd $CURRENT_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

mkdir -p prefix
export PREFIX=$(pwd)/prefix
mkdir build && cd build

export CARES_STATIC=OFF                                                                                                           
export CARES_SHARED=ON                                                                                                            
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_AR=${AR}"   

cmake ${CMAKE_ARGS} .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="$PREFIX" \
      -DCARES_STATIC=${CARES_STATIC} \
      -DCARES_SHARED=${CARES_SHARED} \
      -DCARES_INSTALL=ON \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DCARES_BUILD_TOOLS=OFF \
      -DCARES_BUILD_TESTS=ON \
      -GNinja

echo "-------------------------------------------------------Building the package-------------------------------------"

#Build package
if ! (ninja && ninja install) ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

cd ..
mkdir -p local/cares
cp -r prefix/* local/cares

#During wheel creation for this package we need exported cmake-args. Once script get exit, and if we build wheel through wrapper script, then those are not applicable during wheel creation. So we are generating wheel for this package in script itself.

echo "---------------------------------------------------Building the wheel--------------------------------------------------"

WHL_VERSION=$(echo "$PACKAGE_VERSION" | grep -oE '[0-9_]+$' | tr '_' '.')
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/c/c-ares/pyproject.toml
sed -i "s/{PACKAGE_VERSION}/$WHL_VERSION/g" pyproject.toml

python -m build --wheel --no-isolation --outdir="$CURRENT_DIR/"

echo "----------------------------------------------Testing pkg-------------------------------------------------------"
cd build
#Test package
if ! (ninja test) ; then
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
