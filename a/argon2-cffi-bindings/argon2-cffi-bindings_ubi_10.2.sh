#!/bin/bash -e
#
# -----------------------------------------------------------------------------
#
# Package           : argon2-cffi-bindings
# Version           : 26.1.0
# Source repo       : https://github.com/hynek/argon2-cffi-bindings
# Tested on         : UBI:10.2
# Language          : Python
# Ci-Check      : True
# Script License    : Apache License, Version 2.0
# Maintainer        : tejasBadjateIBM <Tejas.Badjate@ibm.com>
#
# Disclaimer        : This script has been tested in root mode on given
# ==========          platform using the mentioned version of the package.
#                     It may not work as expected with newer versions of the
#                     package and/or distribution. In such case, please
#                     contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
# Variables
PACKAGE_NAME=argon2-cffi-bindings
PACKAGE_VERSION=${1:-26.1.0}
PACKAGE_URL=https://github.com/hynek/argon2-cffi-bindings
PACKAGE_DIR=./argon2-cffi-bindings
CURRENT_DIR="${PWD}"

#install dependencies
yum install -y wget git make python3.14 python3.14-devel python3.14-pip  openssl-devel cmake unzip

yum install gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ gcc-toolset-15-gcc-gfortran -y

# ---------------------------------------------------------------------------
# Activate GCC Toolset 15 (SCL removed in UBI 10 — use PATH export)
# ---------------------------------------------------------------------------
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi

export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:${LD_LIBRARY_PATH:-}"

export CC="/opt/rh/gcc-toolset-15/root/usr/bin/gcc"
export CXX="/opt/rh/gcc-toolset-15/root/usr/bin/g++"

#build and install libargon2
git clone https://github.com/P-H-C/phc-winner-argon2.git
cd phc-winner-argon2
make
make install
cd $CURRENT_DIR

#clone and build argon2-cffi-bindings
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init --recursive

python3.14 -m pip install tox wheel build argon2-cffi setuptools setuptools-scm

if ! python3.14 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run test cases
if ! tox -e py3 ; then
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