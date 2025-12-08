#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : netty
# Version       : netty-4.1.94.Final
# Language      : Java
# Source repo   : https://github.com/netty/netty
# Tested on     : UBI 8.7
# Ci-Check  : True
# Script License: Apache-2.0 License
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

WORKDIR=`pwd`
PACKAGE_NAME=netty
PACKAGE_URL=https://github.com/netty/netty
PACKAGE_VERSION=${1:-netty-4.1.94.Final}

yum install -y make maven git sudo wget gcc-c++ apr-devel perl go openssl-devel automake autoconf libtool libstdc++-static

wget https://github.com/Kitware/CMake/releases/download/v3.21.2/cmake-3.21.2.tar.gz
tar -xvf cmake-3.21.2.tar.gz
cd cmake-3.21.2
./bootstrap
make
make install
cd ..

git clone https://github.com/ninja-build/ninja.git && cd ninja
git checkout v1.10.2
cmake -Bbuild-cmake -H.
cmake --build build-cmake
sudo ln -sf $WORKDIR/ninja/build-cmake/ninja /usr/bin/ninja
cd ..

#netty requires netty-tcnative binaries to build and test ,community made this changes to build netty-tcnative binaries,tried to build and test the netty-tcnative with the following link:https://github.com/linux-on-ibm-z/docs/wiki/Building-netty-tcnative
git clone https://github.com/netty/netty-tcnative.git 
cd netty-tcnative/
git checkout netty-tcnative-parent-2.0.61.Final
sed -i '85,85 s/chromium-stable/patch-s390x-Jan2021/g' pom.xml
sed -i '89,89 s/1ccef4908ce04adc6d246262846f3cd8a111fa44/d83fd4af80af244ac623b99d8152c2e53287b9ad/g' pom.xml
sed -i '54,54 s/boringssl.googlesource.com/github.com\/linux-on-ibm-z/g' boringssl-static/pom.xml
sed -i '55,55 s/chromium-stable/patch-s390x-Jan2021/g' boringssl-static/pom.xml
./mvnw clean install
cd ..

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! ./mvnw clean install -DskipTests -Dtcnative.classifier=linux-ppcle_64-fedora ; then
       echo "------------------$PACKAGE_NAME:Install_fails---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
       exit 1
fi

if ! ./mvnw test -Dtcnative.classifier=linux-ppcle_64-fedora -pl -:netty-handler,-:netty-codec,-:netty-codec-http2,-:netty-codec-http,-:netty-handler-ssl-ocsp,-:netty-transport-sctp,-:netty-transport-native-epoll,-:netty-testsuite-osgi ; then
      echo "------------------$PACKAGE_NAME::Install_and_Test_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
      exit 2
else
      echo "------------------$PACKAGE_NAME::Install_and_Test_success-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
      exit 0
fi

#skipping some modules for netty test:
#for netty-handler module there is open issue:https://github.com/netty/netty/issues/13116
#for netty-codec,netty-codec-http2,netty-codec-http modules requires brotli library which is not supported on power.
#for netty-handler-ssl-ocsp,netty-transport-sctp,netty-transport-native-epoll,netty-testsuite-osgi modules depends on netty-handler module.
