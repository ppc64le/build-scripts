#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : glance
# Version       : zed-eom
# Source repo   : https://github.com/openstack/glance
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
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
PACKAGE_NAME=glance
PACKAGE_VERSION=${1:-zed-eom}
PACKAGE_URL=https://github.com/openstack/glance

yum install openssl openssl-devel -y
yum install -y git wget gcc gcc-c++ python3 python3-pip python3-devel python3-psycopg2 libxslt libxslt-devel make libpq libpq-devel cmake xz libaio  ninja-build glib2 glib2-devel bzip2 pkgconfig diffutils

wget https://rpmfind.net/linux/centos-stream/9-stream/AppStream/ppc64le/os/Packages/pixman-0.40.0-5.el9.ppc64le.rpm
rpm -i pixman-0.40.0-5.el9.ppc64le.rpm

wget https://rpmfind.net/linux/centos-stream/9-stream/AppStream/ppc64le/os/Packages/pixman-devel-0.40.0-5.el9.ppc64le.rpm
rpm -i pixman-devel-0.40.0-5.el9.ppc64le.rpm

wget https://download.qemu.org/qemu-6.2.0.tar.xz
tar xvJf qemu-6.2.0.tar.xz
cd qemu-6.2.0
./configure --enable-vdi
make
make install
cd ..

curl https://sh.rustup.rs -sSf | sh -s -- -y
source ~/.cargo/env

git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

pip3 install "cython<3.0.0" wheel tox && pip3 install --no-build-isolation pyyaml==6.0

if ! python3 -m pip install -r requirements.txt ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
python3 -m pip install -r test-requirements.txt
if ! tox -e py39 ; then
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