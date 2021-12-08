# ----------------------------------------------------------------------------
#
# Package       : vert.x
# Version       : 3.9.7 and 4.1.2
# Source repo   : https://github.com/eclipse-vertx/vert.x
# Tested on     : rhel UBI 8.4
# Script License: Apache License, Version 2 or later
# Maintainer's  : Santosh Magdum <santosh.magdum@us.ibm.com>
#                 Priya Seth <priya.seth@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

PACKAGE_NAME=vert.x
PACKAGE_PATH=github.com/eclipse-vertx/vert.x
PACKAGE_VERSION=${1:-3.9.7}
PACKAGE_URL=https://github.com/eclipse-vertx/vert.x

BUILD_HOME=`pwd`

echo "`date +'%d-%m-%Y %T'` - Staring eclipse vert.x build. Dependencies will be cloned in $BUILD_HOME"

# ------- Install dependencies -------

yum -y install maven make python3

yum -y install subscription-manager.ppc64le
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
subscription-manager repos --enable rhel-7-for-power-le-extras-rpms
yum -y install epel-release

yum -y install gcc-c++.ppc64le
yum -y install wget
yum -y install git
yum -y install java-1.8.0-openjdk-devel
dnf install openssl-devel.ppc64le -y
dnf group install "Development Tools" -y

dnf install ninja-build.ppc64le -y
dnf install golang -y
dnf install autoconf -y
dnf install automake -y
dnf install libtool -y
dnf install make tar glibc-devel libaio-devel openssl-devel lksctp-tools -y
dnf install apr-devel apr-util-devel -y

ln -s /usr/bin/python3 /usr/bin/python

echo "`date +'%d-%m-%Y %T'` - Installed Standard Packages -----------------------------------"
echo "---------------------------------------------------------------------------------------"


# ------- Clone and build source -------
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.312.b07-2.el8_5.ppc64le/

cd $BUILD_HOME

# --------- Installing cmake version 3.21.2 -----------------
echo "--------- Installing cmake version 3.21.2 -----------------"

wget https://github.com/Kitware/CMake/releases/download/v3.21.2/cmake-3.21.2.tar.gz
tar -xvf cmake-3.21.2.tar.gz
cd cmake-3.21.2
./bootstrap
make
make install
cd ..


# --------- Installing ninja version v1.4.0 -----------------
echo "--------- Installing ninja version v1.4.0 -----------------"
git clone git://github.com/ninja-build/ninja.git
cd ninja
git checkout v1.4.0
./bootstrap.py
cp -r ./ninja /usr/bin/
ninja --version
cd ..


#-------- Building tcnative version 2.0.36.Final ----------------
echo "`date +'%d-%m-%Y %T'` - Installed Build Dependencies -----------------------------------"
echo "-------- Building tcnative version 2.0.36.Final ----------------"

git clone --recurse https://github.com/netty/netty-tcnative.git
cd netty-tcnative
git checkout netty-tcnative-parent-2.0.36.Final

./mvnw clean install -DskipTests
cd ..

#-------- Building netty version 4.1.60.Final ----------------
echo "`date +'%d-%m-%Y %T'` - Installed Build Dependencies -----------------------------------"
echo "-------- Building netty version 4.1.60.Final ----------------"

git clone --recurse https://github.com/netty/netty
cd netty
git checkout netty-4.1.60.Final  # version checkout
mvn clean install -DskipTests
cd ..


if [[ $# -ne 0 ]] ; then
i    git clone -b $1 $PACKAGE_URL
else
    git clone $PACKAGE_URL
fi

cd vert.x

git checkout $PACKAGE_VERSION

mvn clean install

cd $BUILD_HOME

echo "`date +'%d-%m-%Y %T'` - Installed eclipse vert.x ---------------------------------------"
echo "- --------------------------------------------------------------------------------------"
