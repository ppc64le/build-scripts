#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : protobuf-java
# Version       : v3.11.1(default)
# Source repo   : https://github.com/protocolbuffers/protobuf.git
# Tested on     : rhel 8
# Language      : Java,C++
# Travis-Check  : True
# Script License: Apache License Version 2.0
# Maintainer    : Sachin Kakatkar <sachin.kakatkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#To run script:./protobuf-java_rhel_8.sh v3.11.1
#!/bin/bash

WORKDIR=`pwd`
PACKAGE_NAME=protobuf
PACKAGE_VERSION=$1
PACKAGE_URL=https://github.com/protocolbuffers/protobuf.git

if [ -z "$1" ]
  then
    PACKAGE_VERSION=v3.11.1
fi
dnf install make maven git sudo wget gcc-c++ apr-devel perl openssl-devel automake autoconf libtool -y

#Install latest cmake
wget https://github.com/Kitware/CMake/releases/download/v3.21.2/cmake-3.21.2.tar.gz
tar -xvf cmake-3.21.2.tar.gz
cd cmake-3.21.2
./bootstrap
make
make install
cd $WORKDIR

#clone and build
git clone $PACKAGE_URL
cd protobuf
git checkout $PACKAGE_VERSION
./autogen.sh
./configure
make
make install
cd java
mvn clean install

