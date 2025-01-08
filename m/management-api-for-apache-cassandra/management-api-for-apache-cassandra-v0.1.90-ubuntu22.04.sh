#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : management-api-for-apache-cassandra 
# Version       : v0.1.90
# Source repo   : github.com/k8ssandra/management-api-for-apache-cassandra 
# Tested on     : Ubuntu 22.04 (docker)
# Language      : Java
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Sumit Dubey <Sumit.Dubey2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=management-api-for-apache-cassandra
PACKAGE_VERSION=${1:-v0.1.90}
PACKAGE_URL=https://github.com/k8ssandra/${PACKAGE_NAME}.git

echo fs.inotify.max_user_watches=655360 | tee -a /etc/sysctl.conf
echo fs.inotify.max_user_instances=1280 | tee -a /etc/sysctl.conf
sysctl -p

#Install dependencies
apt update -y
DEBIAN_FRONTEND=noninteractive apt install -y \
    build-essential \
    git \
    zip unzip \
    curl \
    sudo \
    wget \
    autoconf \
    automake \
    openjdk-11-jdk \
    python3-dev \
    libtool-bin \
    libapr1-dev \
    libaprutil1-dev \
    libssl-dev \
    ninja-build \
    pkg-config \
    cmake

wdir=`pwd`

#Install maven
export JAVA_HOME='/usr/lib/jvm/java-11-openjdk-ppc64el'
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH
wget https://archive.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
tar -xvf apache-maven-3.6.3-bin.tar.gz
rm -rf apache-maven-3.6.3-bin.tar.gz
export M2_HOME="$wdir/apache-maven-3.6.3"
export PATH="$M2_HOME/bin:$PATH"

#Install docker
DEBIAN_FRONTEND=noninteractive apt-get install ca-certificates curl gnupg lsb-release init -y
mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
dockerd > /dev/null 2>&1 &
sleep 5
docker run hello-world

#Get code and apply patch
cd $wdir
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git apply ../$PACKAGE_NAME-$PACKAGE_VERSION.patch

#Build docker image
docker buildx build --load --build-arg CASSANDRA_VERSION=4.1.7 --tag cr.k8ssandra.io/k8ssandra/cass-management-api:4.1.7 --file cassandra/Dockerfile-4.1 --platform linux/ppc64le .

#Build package
mvn -DskipTests package

#Install netty tcnative
cd $wdir && git clone https://github.com/netty/netty-tcnative.git && cd netty-tcnative && git checkout netty-tcnative-parent-2.0.69.Final
sed -i "s#<module>boringssl-static</module>##g" pom.xml
mvn install -DskipTests
cp $wdir/netty-tcnative/openssl-static/target/native-jar-work/META-INF/native/libnetty_tcnative_linux_ppcle_64.so /usr/lib/

#Install netty
cd $wdir && git clone https://github.com/netty/netty.git && cd netty && git checkout netty-4.1.116.Final
cd transport-native-unix-common && mvn install -DskipTests
cd ../transport-native-epoll && mvn install -DskipTests
cd ../common && mvn install -DskipTests
cd ../all && mvn install -DskipTests
cp $wdir/netty/transport-native-epoll/target/native-build/target/lib/libnetty_transport_native_epoll_ppcle_64.so /usr/lib/

#Install netty tcnative
cd $wdir && mkdir netty58 && cd netty58
git clone https://github.com/netty/netty-tcnative.git && cd netty-tcnative && git checkout netty-tcnative-parent-2.0.63.Final
sed -i "s#<module>boringssl-static</module>##g" pom.xml
mvn install -DskipTests
mkdir -p $wdir/management-api-for-apache-cassandra/management-api-server/.cassandra-bin/apache-cassandra-4.0.15/lib/
cp $wdir/netty58/netty-tcnative/openssl-static/target/netty-tcnative-openssl-static-2.0.63.Final.jar $wdir/management-api-for-apache-cassandra/management-api-server/.cassandra-bin/apache-cassandra-4.0.15/lib/netty-tcnative-boringssl-static-2.0.36.Final.jar

#Install netty
cd $wdir/netty58 && git clone https://github.com/netty/netty.git && cd netty && git checkout netty-4.1.58.Final
cd transport-native-unix-common && mvn install -DskipTests
cd ../transport-native-epoll && mvn install -DskipTests
cd ../common && mvn install -DskipTests
cd ../all && mvn install -DskipTests
cp $wdir/netty58/netty/all/target/netty-all-4.1.58.Final.jar $wdir/management-api-for-apache-cassandra/management-api-server/.cassandra-bin/apache-cassandra-4.0.15/lib/netty-all-4.1.58.Final.jar

#Unit and integration tests
cd $wdir/$PACKAGE_NAME
docker tag cr.k8ssandra.io/k8ssandra/cass-management-api:4.1.7 mgmtapi-dockerfile-4.1-test:latest
rm -rf ./management-api-agent-common/src/test/java/io/k8ssandra/metrics/  #Metrics not supported on power
mvn integration-test -Drun4.1tests=true

#Run the image
#docker run --privileged -e USE_MGMT_API=true -p 8080:8080 -it --rm cr.k8ssandra.io/k8ssandra/cass-management-api:4.1.7

#Conclude
set +ex
echo "Build and tests Successful!"

