#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : kcov
# Version          : v42
# Source repo      : https://github.com/SimonKagstrom/kcov
# Tested on        : UBI:9.3
# Language         : C++
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

PACKAGE_NAME=kcov
PACKAGE_VERSION=${1:-v42}
PACKAGE_URL=https://github.com/SimonKagstrom/kcov

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install -y git gcc gcc-c++ make wget cmake elfutils-libelf libcurl-devel gcc-toolset-12-binutils-devel-2.38-19.el9 elfutils zlib-devel openssl-devel libzstd
yum install -y https://dl.fedoraproject.org/pub/epel/9/Everything/ppc64le/Packages/e/epel-release-9-7.el9.noarch.rpm
wget https://rpmfind.net/linux/centos-stream/9-stream/AppStream/ppc64le/os/Packages/libzstd-devel-1.5.1-2.el9.ppc64le.rpm
rpm -i libzstd-devel-1.5.1-2.el9.ppc64le.rpm
yum install binutils rust-lzma-sys+default-devel.noarch -y
wget https://rpmfind.net/linux/centos-stream/9-stream/AppStream/ppc64le/os/Packages/elfutils-libelf-devel-0.189-3.el9.ppc64le.rpm
rpm -i elfutils-libelf-devel-0.189-3.el9.ppc64le.rpm
wget https://rpmfind.net/linux/centos-stream/9-stream/AppStream/ppc64le/os/Packages/elfutils-devel-0.189-3.el9.ppc64le.rpm
rpm -i elfutils-devel-0.189-3.el9.ppc64le.rpm

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
mkdir build build-tests
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr/local ..

if ! make && make install ; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi

cd .. && cd build-tests

if ! cmake ../tests && make ; then
    echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_and_Test_fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi
