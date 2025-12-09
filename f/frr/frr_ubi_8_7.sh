#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : frr 
# Version       : frr-9.0.1
# Source repo   : https://github.com/FRRouting/frr
# Tested on     : UBI: 8.7
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

# Variables
export PACKAGE_NAME=frr
export PACKAGE_URL=https://github.com/FRRouting/frr
export PACKAGE_VERSION=${1:-"frr-9.0.1"}

# Install dependencies
yum install -y wget yum-utils
yum-config-manager --add-repo https://vault.centos.org/8.5.2111/AppStream/ppc64le/os/
yum-config-manager --add-repo https://vault.centos.org/8.5.2111/Devel/ppc64le/os/
yum-config-manager --add-repo https://vault.centos.org/8.5.2111/PowerTools/ppc64le/os/
yum-config-manager --add-repo https://vault.centos.org/8.5.2111/BaseOS/ppc64le/os/
yum-config-manager --add-repo https://vault.centos.org/8.5.2111/HighAvailability/ppc64le/os/
yum-config-manager --add-repo https://vault.centos.org/8.5.2111/centosplus/ppc64le/os/
yum-config-manager --add-repo https://vault.centos.org/8.5.2111/cr/ppc64le/os/
yum-config-manager --add-repo https://vault.centos.org/8.5.2111/extras/ppc64le/os/
yum-config-manager --add-repo https://vault.centos.org/8.5.2111/fasttrack/ppc64le/os/
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

yum install -y git wget gcc gcc-c++ make cmake autoconf automake libtool pkgconf-pkg-config.ppc64le info.ppc64le json-c.ppc64le python39-devel.ppc64le  gzip tar bzip2 zip unzip zlib-devel protobuf-c.ppc64le  java-11-openjdk-devel  libffi-devel clang clang-devel llvm-devel llvm-static clang-libs readline.ppc64le ncurses-devel.ppc64le  pcre2-devel.ppc64le libcap.ppc64le

yum install -y rpm-build git autoconf pcre-devel systemd-devel automake libtool make readline info groff-base json-c pam  python3-pytest python39-devel libcap platform-python-devel protobuf-c protobuf protobuf-c-devel protobuf-devel

yum install -y readline-devel texinfo net-snmp-devel pkgconfig json-c-devel pam-devel bison flex c-ares-devel python3-sphinx libcap-devel  protobuf-c-devel


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
git checkout v2.1.4
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