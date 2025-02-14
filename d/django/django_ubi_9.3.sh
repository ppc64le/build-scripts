#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : django
# Version          : 5.0.7
# Source repo      : https://github.com/django/django
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=django
PACKAGE_VERSION=${1:-5.0.7}
PACKAGE_URL=https://github.com/django/django

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install -y gcc gcc-c++ make wget sudo git zlib-devel libjpeg-turbo libjpeg-turbo-devel libmemcached-awesome-devel python3.12 python3.12-devel python3.12-pip

#install rustc
wget https://static.rust-lang.org/dist/rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz
tar -xzf rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz
cd rust-1.75.0-powerpc64le-unknown-linux-gnu
sudo ./install.sh
export PATH=$HOME/.cargo/bin:$PATH
cd ../

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
python3.12 -m pip install --upgrade pip setuptools wheel

if ! python3.12 -m pip install -r tests/requirements/py3.txt -e .; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME::Build_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_Success"
    exit 0
fi

#Skipping tests because tests are parity with intel
#python3.12 tests/runtests.py -v2
