#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : cassandra
# Version          : cassandra-4.1.4
# Source repo      : https://github.com/apache/cassandra
# Tested on        : UBI 8.7
# Language         : Java
# Travis-Check     : False
# Script License   : Apache License, Version 2 or later
# Maintainer       : Sunidhi Gaonkar<Sunidhi.Gaonkar@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

yum install -y java-11-openjdk-devel make git wget gcc-c++ apr-devel perl openssl-devel automake autoconf libtool unzip libstdc++-static golang procps libffi libffi-devel libxslt-devel libxml2-devel

CURRENT_DIR=`pwd`
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

PACKAGE_NAME=cassandra
PACKAGE_URL=https://github.com/apache/cassandra
PACKAGE_VERSION=${1:-cassandra-4.1.4}

#Install ant
cd /opt/
wget https://dlcdn.apache.org//ant/binaries/apache-ant-1.10.13-bin.zip
unzip apache-ant-1.10.13-bin.zip
export ANT_HOME=/opt/apache-ant-1.10.13
export PATH=/opt/apache-ant-1.10.13/bin:$PATH
export ANT_OPTS=-Dfile.encoding=UTF8
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.22.0.7-2.el8.ppc64le
cd ..

#Install maven
wget https://dlcdn.apache.org/maven/maven-3/3.8.8/binaries/apache-maven-3.8.8-bin.tar.gz
tar -zxf apache-maven-3.8.8-bin.tar.gz
cp -R apache-maven-3.8.8 /usr/local
ln -s /usr/local/apache-maven-3.8.8/bin/mvn /usr/bin/mvn
mvn -version

#Install Python
wget https://www.python.org/ftp/python/3.7.4/Python-3.7.4.tgz
tar -xzf Python-3.7.4.tgz
cd Python-3.7.4
./configure
make
make install
ln -sf /usr/local/bin/python3.7 /usr/bin/python3
ln -sf /usr/local/bin/pip3.7 /usr/local/bin/pip3
cd ..

#Install cmake
wget https://github.com/Kitware/CMake/releases/download/v3.21.2/cmake-3.21.2.tar.gz
tar -xvf cmake-3.21.2.tar.gz
cd cmake-3.21.2
./bootstrap
make
make install
cd ..

#Install ninja
git clone https://github.com/ninja-build/ninja.git && cd ninja
git checkout v1.10.2
cmake -Bbuild-cmake -H.
cmake --build build-cmake
ln -sf $WORKDIR/ninja/build-cmake/ninja /usr/bin/ninja
cd ..

#Install netty-tcnative and netty
git clone https://github.com/netty/netty-tcnative.git 
cd netty-tcnative/
git checkout netty-tcnative-parent-2.0.36.Final
./mvnw clean install -Dtcnative.classifier=linux-ppcle_64-fedora


cd / && git clone https://github.com/netty/netty
cd netty
git checkout netty-4.1.58.Final
cd transport-native-unix-common  && mvn clean install -DskipTests && cd .. \
	&& cd transport-native-epoll && mvn clean install -DskipTests && cd .. \
	&& cd all && ./mvnw clean install -DskipTests -Dtcnative.classifier=linux-ppcle_64-fedora
export LD_LIBRARY_PATH=/netty-tcnative/boringssl-static/target/native-jar-work/META-INF/native/:/netty/transport-native-epoll/target/classes/META-INF/native/

cd / && git clone https://github.com/xerial/snappy-java.git
cd snappy-java
git checkout v1.1.10.4
make clean-native native

#Build
cd / && git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git apply $SCRIPT_DIR/Cassandra_4.1.4.diff
ant -Duse.jdk11=true

#Copy snappy-java jar
cd / && mkdir tmp_snappy_java_local
cd tmp_snappy_java_local
cp  ~/.m2/repository/org/xerial/snappy/snappy-java/1.1.10.4/snappy-java-1.1.10.4.jar .
jar xf snappy-java-1.1.10.4.jar
rm -rf snappy-java-1.1.10.4.jar
cd /tmp_snappy_java_local/org/xerial/snappy/native/Linux/ppc64le
rm -rf libsnappyjava.so
cp /snappy-java/target/snappy-1.1.10-Linux-ppc64le/libsnappyjava.so .
cd /tmp_snappy_java_local
jar cf snappy-java-1.1.10.4.jar META-INF  org
cp snappy-java-1.1.10.4.jar  ~/.m2/repository/org/xerial/snappy/snappy-java/1.1.10.4/

#Test
cd /cassandra && ant test -Duse.jdk11=true

#Travis check has been set to false as test-suite takes about 5 hours to exceute.
#Skipped tests are in parity with intel and issue has been raised with the community for the same.
#https://issues.apache.org/jira/browse/CASSANDRA-19425
