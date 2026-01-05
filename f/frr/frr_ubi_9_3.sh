#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : frr 
# Version       : frr-10.0
# Source repo   : https://github.com/FRRouting/frr
# Tested on     : UBI: 9.3
# Language      : c
# Ci-Check  : True
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

set -e

export PACKAGE_NAME=frr
export PACKAGE_URL=https://github.com/FRRouting/frr
export PACKAGE_VERSION=${1:-"frr-10.0"}
HOME_DIR=${PWD}


# Install dependencies
yum install -y wget yum-utils

dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

yum install -y git wget gcc gcc-c++ make cmake autoconf automake libtool pkgconf-pkg-config info json-c python3-devel python3-pytest python3-sphinx gzip tar bzip2 zip unzip zlib-devel protobuf protobuf-devel protobuf-c protobuf-c-devel  java-11-openjdk-devel  libffi-devel clang clang-devel llvm-devel llvm-static clang-libs readline ncurses-devel pcre-devel pcre2-devel libcap rpm-build systemd-devel groff-base platform-python-devel readline-devel texinfo net-snmp-devel pkgconfig json-c-devel pam-devel bison flex c-ares-devel  libcap-devel  

pip3 install pytest

export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-11)(?=.*ppc64le)')
export PATH=$JAVA_HOME/bin:$PATH
export PROTOC=/usr/local/bin/
export PATH=$PROTOC:$PATH
export PROTOBUF_C=/protobuf-c/protobuf-c
export PATH=$PROTOBUF_C:$PATH
ln -sf usr/bin/python3.9 /usr/bin/python3


#installing libyang
git clone https://github.com/CESNET/libyang
cd libyang
git checkout v2.1.128
mkdir build
cd build
cmake ..
make
make install
cp libyang.pc /usr/lib64/pkgconfig
cd ../..

python3.9 -m pip install pytest

export LD_LIBRARY_PATH=/usr/local/lib64

# Clone the repository
cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
sh bootstrap.sh
./configure

# Build package
if !(make && make install); then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi


# Run test cases
if !(make check); then
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
