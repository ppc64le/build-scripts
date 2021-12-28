# ----------------------------------------------------------------------------
#
# Package       : vertx-micrometer-metrics
# Version       : 3.9.7
# Source repo   : https://github.com/vert-x3/vertx-micrometer-metrics
# Tested on     : UBI 8.4
# Script License: Apache License, Version 2 or later
# Maintainer's  : Vikas Gupta <vikas.gupta8@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

set -x
set -e

PACKAGE_NAME=vertx-micrometer-metrics
PACKAGE_VERSION=3.9.7
PACKAGE_URL=https://github.com/vert-x3/vertx-micrometer-metrics

mkdir -p /home/tester
export HOME_DIR=/home/tester

# ------- Install dependencies ------

yum -y install git wget make maven gcc-c++ openssl-devel automake autoconf libtool apr-devel perl
yum -y install java-1.8.0-openjdk-devel

cd $HOME_DIR
echo `pwd`

# --------- Installing cmake version 3.21.2 -----------------
echo "--------- Installing cmake version 3.21.2 -----------------"

wget https://github.com/Kitware/CMake/releases/download/v3.21.2/cmake-3.21.2.tar.gz
tar -xvf cmake-3.21.2.tar.gz
cd cmake-3.21.2
./bootstrap
make
make install
cd ..

# JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.312.b07-2.el8_5.ppc64le

#-------- Building tcnative version 2.0.44.Final ----------------
echo "`date +'%d-%m-%Y %T'` - Installed Build Dependencies -----------------------------------"
echo "-------- Building tcnative version 2.0.44.Final ----------------"

git clone --recurse https://github.com/netty/netty-tcnative.git
cd netty-tcnative
git checkout netty-tcnative-parent-2.0.44.Final

mvn clean install

cd ..


#-------- Building netty version 4.1.51.Final ----------------
echo "`date +'%d-%m-%Y %T'` - Installed Build Dependencies -----------------------------------"
echo "-------- Building transport-native-epoll version 4.1.51.Final ----------------"

git clone --recurse https://github.com/netty/netty
cd netty
git checkout netty-4.1.51.Final  # version checkout

cd transport-native-unix-common

mvn clean install 

cd ..
cd transport-native-epoll
echo `pwd`
mvn clean install

cd ../..

echo "-------- Building transport-native-epoll version 4.1.51.Final is successful----------------"

if ! git clone --recurse $PACKAGE_URL; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
	exit 0
fi

export HOME_DIR=/home/tester/$PACKAGE_NAME
cd $HOME_DIR
git checkout $PACKAGE_VERSION
#cd $PACKAGE_NAME

sed -i 's/linux-x86_64/linux-ppcle_64/g' /home/tester/vertx-micrometer-metrics/pom.xml

mvn clean install

echo "-------- Building $PACKAGE_NAME is successful----------------"

