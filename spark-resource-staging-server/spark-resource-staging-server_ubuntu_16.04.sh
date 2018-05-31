# ----------------------------------------------------------------------------
#
# Package	: spark-resource-staging-server
# Version	: 2.2-kubernetes
# Source repo	: https://github.com/apache-spark-on-k8s/spark
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Script to build spark-resource-staging-server and related docker images.
apt-get update -y
apt-get install -y git wget openjdk-8-jdk openjdk-8-jre maven \
    build-essential docker ng-common

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el
export PATH=$JAVA_HOME/bin:$PATH

echo "------------------------------- sbt install -----------------------------"
WDIR=`pwd`
wget http://dl.bintray.com/sbt/debian/sbt-0.13.6.deb
update-ca-certificates -f
dpkg -i sbt-0.13.6.deb
rm sbt-0.13.6.deb

echo "------------------------------- zinc install ----------------------------"
cd $WDIR
git clone https://github.com/typesafehub/zinc
cd zinc
sbt scriptit
cd nailgun
make install

echo "------------------------------- spark build -----------------------------"
cd $WDIR
git clone https://github.com/apache-spark-on-k8s/spark
# git clone https://github.com/apache/spark.git
cd spark
build/mvn -DskipTests -Pkubernetes clean package install

echo "------------------------------- copy JARs -------------------------------"
# copy JAR files.
mkdir jars
cp assembly/target/scala-2.11/jars/* jars

echo "------------------------------- copy docker -----------------------------"
# copy docker files.
mkdir dockerfiles
cd dockerfiles
mkdir driver executor driver-py executor-py driver-r executor-r init-container shuffle-service resource-staging-server spark-base
cp -rp ../resource-managers/kubernetes/integration-tests/src/main/docker/integration-test-asset-server/* integration-test-asset-server
cp -rp ../resource-managers/kubernetes/docker-minimal-bundle/src/main/docker/resource-staging-server/* resource-staging-server
cp -rp ../resource-managers/kubernetes/docker-minimal-bundle/src/main/docker/executor/* executor
cp -rp ../resource-managers/kubernetes/docker-minimal-bundle/src/main/docker/spark-base/* spark-base
cp -rp ../resource-managers/kubernetes/docker-minimal-bundle/src/main/docker/shuffle-service/* shuffle-service
cp -rp ../resource-managers/kubernetes/docker-minimal-bundle/src/main/docker/executor-r/* executor-r
cp -rp ../resource-managers/kubernetes/docker-minimal-bundle/src/main/docker/driver-py/* driver-py
cp -rp ../resource-managers/kubernetes/docker-minimal-bundle/src/main/docker/driver-r/* driver-r
cp -rp ../resource-managers/kubernetes/docker-minimal-bundle/src/main/docker/driver/* driver
cp -rp ../resource-managers/kubernetes/docker-minimal-bundle/src/main/docker/init-container/* init-container
cp -rp ../resource-managers/kubernetes/docker-minimal-bundle/src/main/docker/executor-py/* executor-py
cd ..

echo "------------------------------- build docker ----------------------------"
./sbin/build-push-docker-images.sh -r docker.io/myusername -t my-tag build
