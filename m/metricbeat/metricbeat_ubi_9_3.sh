#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : metricbeat
# Version       : v8.13.4
# Source repo   : https://github.com/elastic/beats
# Tested on     : UBI: 9.3
# Language      : go
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex


# Variables
PACKAGE_NAME=metricbeat
PACKAGE_URL=https://github.com/elastic/beats
PACKAGE_VERSION=${1:-v8.13.4}
GO_VERSION=${GO_VERSION:-1.21.7}
CURRENT_DIR=`pwd`
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

#Install dependencies
sudo yum install git make gcc wget gcc-c++ openssl openssl-devel -y

#Install go
wget https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin
go version

#Install Python3.10
sudo yum install -y gcc openssl-devel bzip2-devel libffi-devel wget xz zlib-devel
wget https://www.python.org/ftp/python/3.10.0/Python-3.10.0.tar.xz
tar xf Python-3.10.0.tar.xz
cd Python-3.10.0
./configure --prefix=/usr/local --enable-optimizations
make -j4
echo $?
python3 --version
sudo make install
python3.10 --version
cd ..
sudo ln -sf $(which python3.10) /usr/bin/python3
sudo ln -sf $(which pip3.10) /usr/bin/pip3
python3 -V && pip3 -V
python3 -m pip install --upgrade pip setuptools tox
export TOXENV=py310

# Cloning the repository from remote to local
git clone $PACKAGE_URL
cd beats
git checkout $PACKAGE_VERSION
make
cd $PACKAGE_NAME

#skipping TestDbusEnvConnection test as it require dbus-daemon which need docker inside container.
sudo sed -i '/func TestDbusEnvConnection(t \*testing\.T) {/ {n
s|^|\t\tt.Skip("Skipping this test as it requires dbus-daemon")\n|}' "module/system/service/service_unit_test.go"

# Build package
if !(mage build) ; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Run test cases
if !(mage goUnitTest); then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi
