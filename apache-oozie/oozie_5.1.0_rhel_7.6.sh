# ----------------------------------------------------------------------------
#
# Package       : apache-oozie
# Version       : 5.1.0
# Source repo   : https://github.com/apache/oozie
# Tested on     : rhel_7.6
# Script License: Apache License, Version 2 or later
# Maintainer    : Shivani Junawane <shivanij@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

if [ $# -eq 1 ]
then
    WORKDIR=$1
else
    WORKDIR=~
fi

VERSION=5.1.0

# install dependencies
yum update -y
yum install -y git java-1.8.0-openjdk rh-maven35 wget gcc-c++ make
source scl_source enable rh-maven35

# Install J2V8 dependency
cd $WORKDIR
git clone https://github.com/eclipsesource/J2V8
cd J2V8
git checkout 32a83caba893f8157c362e6a154abb1b255cdfb8
export CCFLAGS="${CCFLAGS} -fPIC" 
export CXXFLAGS="${CXXFLAGS} -fPIC" 
export CPPFLAGS="${CPPFLAGS} -fPIC" 
sh ./build-node.sh
cd jni
g++ -I ../node -I /usr/lib/jvm/java-1.8.0-openjdk/include/ -I ../node/deps/v8 -I../node/deps/v8/include \
-I /usr/lib/jvm/java-1.8.0-openjdk/include/linux/ \
-I ../node/src \
com_eclipsesource_v8_V8Impl.cpp -std=c++11 -fPIC -shared -o libj2v8_linux_ppc64le.so \
-Wl,--whole-archive ../node/out/Release/obj.target/libnode.a  -Wl,--no-whole-archive \
-Wl,--start-group \
../node/out/Release/libv8_libbase.a \
../node/out/Release/libv8_libplatform.a \
../node/out/Release/libv8_base.a \
../node/out/Release/libv8_nosnapshot.a \
../node/out/Release/libuv.a \
../node/out/Release/libopenssl.a \
../node/out/Release/libhttp_parser.a \
../node/out/Release/libgtest.a \
../node/out/Release/libzlib.a \
../node/out/Release/libcares.a \
-Wl,--end-group \
-lrt -D NODE_COMPATIBLE=1
cd ..
sed -i 	's/arm64/ppc64le/g' pom.xml
mvn clean verify

# Install oozie
cd $WORKDIR
git clone https://github.com/apache/oozie
cd oozie
git checkout release-$VERSION
# Test cases require hadoop and pig
wget http://public-repo-1.hortonworks.com/HDP/centos7-ppc/3.x/updates/3.1.0.0/hdp.repo
cp hdp.repo /etc/yum.repos.d/
yum repolist
yum install -y hadoop pig
# patch for pyspark test case
wget https://issues.apache.org/jira/secure/attachment/12954580/OOZIE-3401-02.patch
patch --force < OOZIE-3401-02.patch
export LD_LIBRARY_PATH=$WORKDIR/J2V8/jni
sed -i 's|http://repo1.maven.org/maven2|https://repo1.maven.org/maven2|g' pom.xml
mvn clean install
