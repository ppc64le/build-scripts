#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : numpy
# Version       : v2.2.2
# Source repo   : https://github.com/numpy/numpy
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shubham Garud <Shubham.Garud@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=numpy
PACKAGE_VERSION=${1:-v2.2.2}
PACKAGE_URL=https://github.com/numpy/numpy.git
PACKAGE_DIR=$PACKAGE_NAME
yum install -y python3.12  python3.12-devel python3.12-pip git gcc-gfortran make g++ openblas

ln -sf /usr/bin/python3.12 /usr/bin/python3

python3 -m pip install --upgrade pip
python3 -m pip install tox Cython pytest hypothesis wheel meson ninja

export SITE_PACKAGE_PATH=/usr/local/lib/python3.12/site-packages
export OpenBLAS_HOME="/usr/include/openblas"

UNAME_M=$(uname -m)


#clone package
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

case "$UNAME_M" in
    ppc64*)
        # Optimizations trigger compiler bug.
         export CXXFLAGS="$(echo ${CXXFLAGS} | sed -e 's/ -fno-plt//')"
         export CFLAGS="$(echo ${CFLAGS} | sed -e 's/ -fno-plt//')"
        ;;
    *)
        EXTRA_OPTS=""
        ;;
esac

if ! (python3 -m pip install . );then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

cd ..

if ! (python3 -m pytest --pyargs numpy -m 'not slow'); then
    echo "--------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi