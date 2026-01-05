#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : slurm
# Version       : slurm-23-11-5-1
# Source repo   : https://github.com/SchedMD/slurm
# Tested on     : UBI:9.3
# Language      : C
# Ci-Check  : True
# Script License: GNU General Public License v2.0
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=slurm
PACKAGE_VERSION=${1:-slurm-23-11-5-1}
PACKAGE_URL=https://github.com/SchedMD/slurm

yum install -y g++ wget git gcc gcc-c++ make cmake libtool autoconf openssl openssl-devel bzip2-devel zlib-devel pkgconfig xz

#Install munge
wget https://github.com/dun/munge/releases/download/munge-0.5.16/munge-0.5.16.tar.xz
tar xJf munge-0.5.16.tar.xz
cd munge-0.5.16
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --runstatedir=/run
make 
make install
cd ..

git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

./configure

if ! make && make install; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! make check; then
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
