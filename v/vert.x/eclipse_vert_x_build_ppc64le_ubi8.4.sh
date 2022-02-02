#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : vert.x
# Version       : 3.9.7 and 4.1.2
# Source repo   : https://github.com/eclipse-vertx/vert.x
# Tested on     : UBI 8.4
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Vikas Gupta <vikas.gupta8@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=vert.x
PACKAGE_PATH=github.com/eclipse-vertx/vert.x
PACKAGE_VERSION=${1:-3.9.7}
PACKAGE_URL=https://github.com/eclipse-vertx/vert.x

BUILD_HOME=`pwd`

echo "`date +'%d-%m-%Y %T'` - Staring eclipse vert.x build. Dependencies will be cloned in $BUILD_HOME"

# ------- Install dependencies -------

yum -y install git wget gcc-c++ cmake maven make python3 autoconf automake libtool glibc-devel openssl-devel lksctp-tools apr-devel apr-util-devel
yum -y install java-1.8.0-openjdk-devel

ln -s /usr/bin/python3 /usr/bin/python

echo "`date +'%d-%m-%Y %T'` - Installed Standard Packages -----------------------------------"
echo "---------------------------------------------------------------------------------------"

# ------- Clone and build source -------
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.322.b06-2.el8_5.ppc64le/
cd $BUILD_HOME

# Install Go and setup working directory
wget https://golang.org/dl/go1.17.4.linux-ppc64le.tar.gz && \
    tar -C /bin -xf go1.17.4.linux-ppc64le.tar.gz && \
    mkdir -p /home/tester/go/src /home/tester/go/bin /home/tester/go/pkg /home/tester/output

rm -rf go1.17.4.linux-ppc64le.tar.gz
export HOME_DIR=/home/tester

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

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

./mvnw clean install
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

sed -i '/<artifactId>netty-tcnative-boringssl-static<\/artifactId>/ a \ \ \ \ \ \ \<classifier>linux-ppcle_64\<\/classifier>' pom.xml
sed -i '/<artifactId>netty-tcnative-boringssl-static<\/artifactId>/ a \ \ \ \ \ \ \<version>2.0.36.Final\<\/version>' pom.xml

mvn clean install

cd $BUILD_HOME

echo "`date +'%d-%m-%Y %T'` - Installed eclipse vert.x ---------------------------------------"
echo "- --------------------------------------------------------------------------------------"
