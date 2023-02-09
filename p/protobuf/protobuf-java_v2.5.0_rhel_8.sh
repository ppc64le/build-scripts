#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : protobuf-java
# Version       : v2.5.0
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
#To Run script:./protobuf-java_v2.5.0_RHEL_8.sh
dnf install make maven git sudo wget gcc-c++ apr-devel perl openssl-devel automake autoconf libtool -y

#Install latest cmake
wget https://github.com/Kitware/CMake/releases/download/v3.21.2/cmake-3.21.2.tar.gz
tar -xvf cmake-3.21.2.tar.gz
cd cmake-3.21.2
./bootstrap
make
make install
cd ..

git clone https://github.com/protocolbuffers/protobuf.git
cd protobuf
git checkout v2.5.0
git apply ../protobuf_v2.5.0.patch
./autogen.sh
./configure
make
make install
cd java
mvn clean install

