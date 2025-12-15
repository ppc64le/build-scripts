#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pylibdmtx
# Version       : v0.1.10
# Source repo   : https://github.com/NaturalHistoryMuseum/pylibdmtx
# Tested on     : UBI 8.7
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=pylibdmtx
PACKAGE_VERSION=${1:-v0.1.10}
PACKAGE_URL=https://github.com/NaturalHistoryMuseum/pylibdmtx
WDIR=`pwd`


yum install -y git python39 python39-devel gcc gcc-c++ make wget sudo openssl-devel libcurl-devel automake libjpeg-turbo libjpeg-turbo-devel autoconf m4 autoconf atlas-devel libtool diffutils 

#Install rustc
curl https://sh.rustup.rs -sSf | sh -s -- -y
PATH="$HOME/.cargo/bin:$PATH"
source $HOME/.cargo/env
rustc --version

#Build libdmtx binaries
git clone https://github.com/dmtx/libdmtx
cd libdmtx
sh autogen.sh
./configure
make
make install
cd ..

git clone $PACKAGE_URL 
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

python3 -m pip install pytest pytest-cov
pip3 install -r requirements-test.txt
echo "$WDIR/usr/local/lib" | sudo tee /etc/ld.so.conf.d/libdmtx.conf
echo "$WDIR/script/libdmtx/.libs" | sudo tee -a /etc/ld.so.conf.d/libdmtx.conf
export LD_LIBRARY_PATH=/usr/local/lib
sudo ldconfig

if ! python3 setup.py install ;  then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! python3 setup.py test ; then
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
