# ----------------------------------------------------------------------------
#
# Package       : vertx-micrometer-metrics
# Version       : 3.9.10
# Source repo   : https://github.com/vert-x3/vertx-micrometer-metrics
# Tested on     : RHEL UBI 8.4
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

PACKAGE_NAME=vertx-micrometer-metrics
PACKAGE_VERSION=3.9.10
PACKAGE_URL=https://github.com/vert-x3/vertx-micrometer-metrics

mkdir -p /home/tester
export HOME=/home/tester

# ------- Install dependencies ------

yum -y install git wget make maven gcc-c++ openssl-devel automake autoconf libtool
yum -y install java-1.8.0-openjdk-devel

#yum -y install gcc-c++.ppc64le
#yum -y install wget
#yum -y install git
#yum install -y openssl-devel.ppc64le
#yum install -y cmake.ppc64le cmake3.ppc64le

dnf install make maven git sudo wget gcc-c++ apr-devel perl openssl-devel automake autoconf libtool -y

cd $HOME
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

echo "-------- Building transport-native-epoll version 4.1.70.Final is successful----------------"

#-------- Building tcnative version 2.0.44.Final ----------------
echo "`date +'%d-%m-%Y %T'` - Installed Build Dependencies -----------------------------------"
echo "-------- Building transport-native-epoll version 4.1.70.Final ----------------"

git clone --recurse https://github.com/netty/netty
cd netty
git checkout netty-4.1.70.Final # version checkout

cd transport-native-unix-common

mvn clean install 

cd ..
cd transport-native-epoll
echo `pwd`
mvn clean install

cd ../..

echo "-------- Building tcnative version 2.0.44.Final is successful----------------"

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

sed -i '0,/4.1.51/s/4.1.51/4.1.70/g' /home/tester/vertx-micrometer-metrics/pom.xml
sed -i 's/linux-x86_64/linux-ppcle_64/g' /home/tester/vertx-micrometer-metrics/pom.xml

mvn clean install

echo "-------- Building $PACKAGE_NAME is successful----------------"

