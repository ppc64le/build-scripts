#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : pyzmq
# Version          : v26.4.0
# Source repo      : https://github.com/zeromq/pyzmq.git
# Tested on        : UBI:9.5
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod.K1 <Vinod.K1@ibm.com>
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
PACKAGE_VERSION=${1:-v26.4.0}
PACKAGE_URL=https://github.com/zeromq/pyzmq.git
PACKAGE_DIR=pyzmq
CURRENT_DIR="${PWD}"

# Install dependencies
yum install -y git gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran \
    cmake make wget openssl-devel bzip2-devel glibc-static libstdc++-static libffi-devel \
    zlib-devel python-devel python-pip pkg-config automake autoconf libtool

source /opt/rh/gcc-toolset-13/enable
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#install python dependencies
pip install cython==3.0.12 packaging==24.2 pathspec==0.12.1 scikit-build-core==0.11.1 cmake==3.27.9 ninja==1.11.1.4 build pytest pytest-asyncio pytest-timeout

#install
if ! pip install -e . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
# Run tests
if ! pytest -v --timeout=60 --capture=no -p no:warnings --ignore=tests/test_draft.py --ignore=tests/test_cython.py ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
fi

# Building wheel with script itself as it needs to locate the libzmq target file 
if ! python3 -m build --wheel --no-isolation --outdir="$CURRENT_DIR"; then
    echo "------------------$PACKAGE_NAME: Wheel Build Failed ---------------------"
    exit 2
else
    echo "------------------$PACKAGE_NAME: Wheel Build Success -------------------------"
    exit 0
fi
