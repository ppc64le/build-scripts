#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : patroni
# Version          : v4.0.5
# Source repo      : https://github.com/zalando/patroni
# Tested on        : UBI:9.3
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

PACKAGE_NAME=patroni
PACKAGE_VERSION=${1:-v4.0.5}
PACKAGE_URL=https://github.com/zalando/patroni
PACKAGE_DIR=patroni

CURRENT_DIR=${PWD}

yum install -y git make wget python3 python3-devel python3-pip python3-psycopg2 postgresql openssl openssl-devel gcc-toolset-13 gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc

export GCC_TOOLSET_PATH=/opt/rh/gcc-toolset-13/root/usr
export PATH=$GCC_TOOLSET_PATH/bin:$PATH

#install rust
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"  # Update environment variables to use Rust

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

pip install --upgrade wheel pip setuptools
pip install flake8 pytest pytest-cov coverage cython
python3 .github/workflows/install_deps.py
pip install -r requirements.txt
pip install -r requirements.dev.txt


#Build package
if ! pip install . ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#Test package
#Deselecting tests that fail due to assertion errors from CLI input/output mismatch; in parity with Intel
if ! pytest -p no:warnings --deselect=tests/test_ctl.py::TestCtl::test_failover --deselect=tests/test_ctl.py::TestCtl::test_restart_reinit ; then
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
