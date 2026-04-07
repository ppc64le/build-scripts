#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : pyopengl
# Version          : release-3.1.7
# Source repo      : https://github.com/mcfletch/pyopengl
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=pyopengl
PACKAGE_VERSION=${1:-release-3.1.7}
PACKAGE_URL=https://github.com/mcfletch/pyopengl
PACKAGE_DIR=pyopengl/accelerate

CURRENT_DIR=${PWD}

yum install -y git make cmake zip tar wget python3 python3-devel python3-pip gcc-toolset-13 gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc zlib-devel libjpeg-devel openssl openssl-devel freetype-devel pkgconfig mesa-libGL mesa-libGLU
yum remove -y python3-chardet

export GCC_TOOLSET_PATH=/opt/rh/gcc-toolset-13/root/usr
export PATH=$GCC_TOOLSET_PATH/bin:$PATH

#Installing SDL2
wget https://www.libsdl.org/release/SDL2-2.28.5.tar.gz
tar -xzf SDL2-2.28.5.tar.gz
cd SDL2-2.28.5
./configure --prefix=/usr/local
make
make install
ldconfig
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH

declare -A VERSION_BRANCH_MAPPING=(
    ["release-3.1.9"]="master"
)

if [[ -v VERSION_BRANCH_MAPPING[$PACKAGE_VERSION] ]]; then
    branch="${VERSION_BRANCH_MAPPING[$PACKAGE_VERSION]}"
else
    branch="$PACKAGE_VERSION"
fi

cd $CURRENT_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

pip3 install --upgrade pip
pip3 install cython numpy setuptools tox

pip3 install .
cd accelerate

# #Apply patch
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/pyopengl-accelerate/pyopengl-accelerate_release-3.1.7.patch
git apply pyopengl-accelerate_release-3.1.7.patch

#Build package
if ! pip3 install . ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

yum install -y mesa-libEGL mesa-libGL mesa-dri-drivers
pip3 install pytest
# Setting PYOPENGL_PLATFORM=egl to force PyOpenGL to use EGL backend instead of X11/GLX, required for headless environments (no display server).
export PYOPENGL_PLATFORM=egl
#Test package 
if ! pytest ; then
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
