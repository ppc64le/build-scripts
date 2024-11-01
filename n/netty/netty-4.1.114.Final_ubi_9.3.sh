#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : netty
# Version       : netty-4.1.114.Final
# Source repo   : https://github.com/netty/netty
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
PACKAGE_NAME=netty
PACKAGE_URL=https://github.com/netty/netty
PACKAGE_VERSION=${1:-netty-4.1.114.Final}



yum install -y make maven git sudo wget gcc-c++ apr-devel perl go openssl-devel automake autoconf libtool libstdc++-static
yum install -y gcc java-11-openjdk-devel

# Set java 
export JAVA_HOME=$(compgen -G '/usr/lib/jvm/java-11-openjdk-11*')
export PATH="$JAVA_HOME/bin/":$PATH
java -version


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

#Install go lang
wget https://golang.org/dl/go1.17.linux-ppc64le.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.17.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin
go version


#Build and test
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/n/netty-tcnative/netty-tcnative_ubi_9.3.sh
bash netty-tcnative_ubi_9.3.sh netty-tcnative-parent-2.0.66.Final

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

# same testcase failures seen on x86
# if ! ./mvnw test -Dtcnative.classifier=linux-ppcle_64-fedora -pl -:netty-handler,-:netty-codec-http2,-:netty-testsuite,-:netty-transport-native-epoll,-:netty-testsuite-osgi,-:netty-transport-blockhound-tests   ; then
#       echo "------------------$PACKAGE_NAME::Install_and_Test_fails-------------------------"
#       echo "$PACKAGE_URL $PACKAGE_NAME"
#       echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail |  Both_Build_and_Test_Fail"
#       exit 2
# else
#       echo "------------------$PACKAGE_NAME::Install_and_Test_success-------------------------"
#       echo "$PACKAGE_URL $PACKAGE_NAME"
#       echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
#       exit 0
# fi
