#!/bin/bash -e
#----------------------------------------------------------------------------
#
# Package       : netty-tcnative
# Version       : netty-tcnative-parent-2.0.62.Final
# Source repo   : https://github.com/netty/netty-tcnative.git
# Tested on     : UBI 9.3
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Siddesh Sangodkar <siddesh.sangodkar1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


WORKDIR=`pwd`
PACKAGE_NAME=netty-tcnative
PACKAGE_VERSION=$1
PACKAGE_URL=https://github.com/netty/netty-tcnative.git

if [ -z "$1" ]
  then
    PACKAGE_VERSION=netty-tcnative-parent-2.0.62.Final
fi

#Install required dependencies
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf install -y unzip make maven git sudo wget gcc-c++ apr-devel perl openssl-devel automake autoconf libtool ninja-build golang  glibc-devel lksctp-tools apr-util-devel java-11-openjdk-devel perl-core gcc-c++

# Set java 
export JAVA_HOME=$(compgen -G '/usr/lib/jvm/java-11-openjdk-11*')
export PATH="$JAVA_HOME/bin/":$PATH

#Install cmake 21 and above
wget https://github.com/Kitware/CMake/releases/download/v3.21.2/cmake-3.21.2.tar.gz
tar -xvf cmake-3.21.2.tar.gz
cd cmake-3.21.2
./bootstrap
make
make install
cd ..

#Install Ninja tool
git clone https://github.com/ninja-build/ninja.git
cd ninja && ./configure.py --bootstrap
export PATH=$PATH:/ninja/
ninja --version

cd ..

# Install older openssl 
wget https://github.com/openssl/openssl/archive/refs/tags/OpenSSL_1_1_1j.zip
unzip OpenSSL_1_1_1j.zip 
cd ./openssl-OpenSSL_1_1_1j/
./config --prefix=/usr/local/openssl_1_1_1j --openssldir=/usr/local/openssl_1_1_1j/ssl
make && make install
cd ..

#Build and test
git clone $PACKAGE_URL
cd netty-tcnative
git checkout $PACKAGE_VERSION
export CPPFLAGS="-I/usr/local/openssl_1_1_1j/include"


if ! ./mvnw -Dmaven.javadoc.skip=true install -am -pl openssl-dynamic; then
    echo "------------------$PACKAGE_NAME:Install and _fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi 

# if ! ./mvnw -Dmaven.javadoc.skip=true install -am -pl openssl-classes; then
#     echo "------------------$PACKAGE_NAME:Install and _fails-------------------------------------"
#     echo "$PACKAGE_URL $PACKAGE_NAME"
#     echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
#     exit 1
# fi 

exit 0
