#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : cassandra-driver
# Version          : 3.29.0
# Source repo      : http://github.com/datastax/python-driver
# Tested on	   : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=cassandra-driver
PACKAGE_VERSION=${1:-3.29.0}
PACKAGE_URL=http://github.com/datastax/python-driver
PACKAGE_DIR=python-driver

# Install dependencies
yum install -y git gcc gcc-c++ make wget sudo openssl-devel bzip2-devel krb5-devel libffi-devel zlib-devel python-devel python-pip

# Install rust
if ! command -v rustc &> /dev/null
then
    wget https://static.rust-lang.org/dist/rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz
    tar -xzf rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz
    cd rust-1.75.0-powerpc64le-unknown-linux-gnu
    sudo ./install.sh
    export PATH=$HOME/.cargo/bin:$PATH
    rustc -V
    cargo -V
    cd ../
fi

#Install libev
wget https://rpmfind.net/linux/centos-stream/9-stream/BaseOS/ppc64le/os/Packages/libev-4.33-6.el9.ppc64le.rpm
rpm -i libev-4.33-6.el9.ppc64le.rpm
rm -rf libev-4.33-6.el9.ppc64le.rpm

#Install libev-devel
wget https://rpmfind.net/linux/centos-stream/9-stream/CRB/ppc64le/os/Packages/libev-devel-4.33-6.el9.ppc64le.rpm
rpm -i libev-devel-4.33-6.el9.ppc64le.rpm
rm -rf libev-devel-4.33-6.el9.ppc64le.rpm

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

#install necessary Python packages
pip install wheel pytest tox nox mock
pip install -r test-requirements.txt

#Install
if ! (python3 -m pip install .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if !(pytest /python-driver/tests/unit/ -k "not(CloudTests or TestTwistedConnection or _PoolTests)" --ignore=/python-driver/tests/unit/io/test_libevreactor.py --ignore=/python-driver/tests/unit/io/test_asyncioreactor.py); then
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
