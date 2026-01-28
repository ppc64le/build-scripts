#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : pyzmq
# Version          : v25.1.2
# Source repo      : https://github.com/zeromq/pyzmq.git
# Tested on        : UBI:9.5
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Haritha Nagothu <haritha.nagothu2@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=pyzmq
PACKAGE_VERSION=${1:-v25.1.2}
PACKAGE_URL=https://github.com/zeromq/pyzmq.git
PACKAGE_DIR=pyzmq
CURRENT_DIR="${PWD}"

# Install dependencies
yum install -y git gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran \
    cmake make wget openssl-devel bzip2-devel glibc-static libstdc++-static libffi-devel \
    zlib-devel python-devel python-pip pkg-config automake autoconf libtool

source /opt/rh/gcc-toolset-13/enable
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig:$PKG_CONFIG_PATH


wget https://github.com/zeromq/libzmq/releases/download/v4.3.5/zeromq-4.3.5.tar.gz
tar -xzf zeromq-4.3.5.tar.gz
cd zeromq-4.3.5
./configure --prefix=/usr/local
make -j$(nproc)
make install
cd ..

export ZMQ_PREFIX=/usr/local
export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64:$LD_LIBRARY_PATH

git clone $PACKAGE_URL
cd $PACKAGE_NAME 
git checkout $PACKAGE_VERSION

#install python dependencies
pip install cython==3.0.12 packaging pathspec==0.12.1 scikit-build-core==0.11.1 cmake==3.27.9 ninja==1.11.1.4 build
pip install "setuptools_scm[toml]" pytest==6.2.5 pytest-asyncio==0.20.3 "pytest-timeout<2.0" tornado mypy


#install
if ! pip install -e . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

export PYTHONPATH=$PWD/tests:$PWD
if ! pytest -v --timeout=60 --capture=no -p no:warnings; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
