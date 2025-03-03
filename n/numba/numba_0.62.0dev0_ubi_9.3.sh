#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : numba
# Version       : 0.62.0dev0
# Source repo   : https://github.com/numba/numba
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such a case, please
# contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=numba
PACKAGE_VERSION=${1:-0.62.0dev0}
PACKAGE_URL=https://github.com/numba/numba
PACKAGE_DIR=numba
SCRIPT_DIR=$(pwd)

# Install dependencies and tools.

dnf install -y --nodocs https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
yum install -y git  gcc-toolset-13 gcc gcc-c++  make wget python3.11 python3.11-devel python3.11-pip xz-devel bzip2-devel openssl-devel zlib-devel libffi-devel llvm15-devel.ppc64le
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH

export LLVM_CONFIG=/usr/lib64/llvm15/bin/llvm-config
export CFLAGS=-I/usr/include
export CXXFLAGS=-I/usr/include

#clone repository
git clone $PACKAGE_URL
cd  $PACKAGE_DIR
git checkout $PACKAGE_VERSION

python3.11 -m pip install numpy==2.0.2 setuptools

#install
if ! python3.11 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#test
cd ${SCRIPT_DIR}

if ! python3.11 -c "import numba; import numba.core.annotations; import numba.core.datamodel; import numba.core.rewrites; import numba.core.runtime; import numba.core.typing; import numba.core.unsafe; import numba.experimental.jitclass; import numba.np.ufunc; import numba.pycc; import numba.scripts; import numba.testing; import numba.tests; import numba.tests.npyufunc;"; then
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
