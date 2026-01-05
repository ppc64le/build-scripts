#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : hdf5
# Version       : hdf5-1_12_1
# Source repo   : https://github.com/HDFGroup/hdf5
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

PACKAGE_NAME=hdf5
PACKAGE_DIR=hdf5
PACKAGE_VERSION=${1:-hdf5-1_12_1}
PACKAGE_URL=https://github.com/HDFGroup/hdf5

# install core dependencies
yum install -y python3.12 python3.12-pip python3.12-devel git wget  gcc-toolset-13 
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH

LOCAL_DIR=local
CPU_COUNT=`python3.12 -c 'import multiprocessing ; print (multiprocessing.cpu_count())'`

# clone source repository
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION
git submodule update --init

mkdir -p $LOCAL_DIR/$PACKAGE_NAME
export PREFIX=$(pwd)/$LOCAL_DIR/$PACKAGE_NAME

./configure --prefix=${PREFIX} \
            --enable-cxx \
            --enable-fortran \
            --with-pthread=yes \
            --enable-threadsafe \
            --enable-build-mode=production \
            --enable-unsupported \
            --enable-using-memchecker \
            --enable-clear-file-buffers \
            --with-ssl

make -j "${CPU_COUNT}" V=1
make install PREFIX="${PREFIX}"
touch $LOCAL_DIR/$PACKAGE_NAME/__init__.py

#Downloading Pyproject.toml file
wget https://raw.githubusercontent.com/ppc64le/build-scripts/1423375e65a9eb5ab3fb37fe8b8f3e18acafbc97/h/hdf5/pyproject.toml
sed -i s/{PACKAGE_VERSION}/$PACKAGE_VERSION/g pyproject.toml
sed -i 's/version = "hdf5[._-]\([0-9]*\)[._-]\([0-9]*\)[._-]\([0-9]*\)\([._-]*[0-9]*\)"/version = "\1.\2.\3\4"/' pyproject.toml

#install
if ! (python3.12 -m pip install .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#test
if ! make check; then
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
