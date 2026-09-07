#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : management-api-for-apache-cassandra
# Version       : v0.1.120
# Source repo   : https://github.com/k8ssandra/management-api-for-apache-cassandra
# Tested on     : UBI 9.8
# Language      : Java
# Ci-Check      : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Manya Rusiya <Manya.Rusiya@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=management-api-for-apache-cassandra
PACKAGE_VERSION=${1:-v0.1.120}
PACKAGE_URL=https://github.com/k8ssandra/${PACKAGE_NAME}.git

# Install procps-ng first (needed for sysctl)
dnf install -y procps-ng

echo "fs.inotify.max_user_watches=655360" >> /etc/sysctl.conf
echo "fs.inotify.max_user_instances=1280" >> /etc/sysctl.conf
sysctl -p || true

# Install build dependencies
# --allowerasing is required on UBI 9 ppc64le to replace curl-minimal with curl
dnf install -y --allowerasing \
    git \
    autoconf \
    automake \
    cmake \
    gcc \
    gcc-c++ \
    make \
    patch \
    java-11-openjdk \
    java-11-openjdk-devel \
    wget \
    python3-devel \
    libtool \
    apr-devel \
    apr-util-devel \
    openssl-devel \
    ninja-build \
    golang \
    pkgconf-pkg-config \
    tar \
    gzip \
    which \
    perl \
    perl-FindBin \
    findutils

wdir=$(pwd)

# Java and Maven setup
# On UBI/RHEL 9 ppc64le the JDK lands at java-11-openjdk (no arch suffix)
export JAVA_HOME='/usr/lib/jvm/java-11-openjdk'
export JRE_HOME=${JAVA_HOME}
export PATH=${JAVA_HOME}/bin:$PATH

wget https://archive.apache.org/dist/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz
tar -xvf apache-maven-3.9.9-bin.tar.gz
rm -f apache-maven-3.9.9-bin.tar.gz
export M2_HOME="$wdir/apache-maven-3.9.9"
export PATH="$M2_HOME/bin:$PATH"

# Container runtime — Podman (Docker CE has no ppc64le RHEL 9 repo)
# Remove any stale docker-ce repo that would cause dnf 404 errors
rm -f /etc/yum.repos.d/docker-ce.repo
dnf install -y podman podman-docker fuse-overlayfs slirp4netns

# Alias podman as docker so docker-java Maven test library works
ln -sf /usr/bin/podman /usr/local/bin/docker
export DOCKER_HOST="unix:///run/podman/podman.sock"
mkdir -p /run/podman
podman system service --time=0 unix:///run/podman/podman.sock &
sleep 5

# Verify container runtime
podman --version
docker version
docker run hello-world

#podman load -i /cassandra-4.1.11.tar

# Get source and apply ppc64le patch
cd $wdir
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git apply ../$PACKAGE_NAME-$PACKAGE_VERSION.patch

# Build (skip tests; netty natives not yet available)
mvn install -DskipTests -Dskip.surefire.tests

# Build Docker image via Podman (native ppc64le — no --platform or --load flags)
podman build   --network=host   --build-arg CASSANDRA_VERSION=4.1.11   -t cr.k8ssandra.io/k8ssandra/cass-management-api:4.1.11   -f cassandra/Dockerfile-4.1.ubi .


# Install netty-tcnative 2.0.77 (for Cassandra 4.1 native libs)
cd $wdir
git clone https://github.com/netty/netty-tcnative.git
cd netty-tcnative
git checkout netty-tcnative-parent-2.0.77.Final
sed -i "s#<module>boringssl-static</module>##g" pom.xml
mvn install -DskipTests
mvn install:install-file \
    -Dfile=openssl-dynamic/target/netty-tcnative-2.0.77.Final-linux-ppcle_64.jar \
    -DgroupId=io.netty \
    -DartifactId=netty-tcnative \
    -Dversion=2.0.77.Final \
    -Dclassifier=linux-ppcle_64-fedora \
    -Dpackaging=jar
cp $wdir/netty-tcnative/openssl-static/target/native-jar-work/META-INF/native/libnetty_tcnative_linux_ppcle_64.so /usr/lib/

# Install netty 4.1.135 (for Cassandra 4.1 native transport)
cd $wdir
git clone https://github.com/netty/netty.git
cd netty
git checkout netty-4.1.135.Final
cd transport-native-unix-common && mvn install -DskipTests
cd ../transport-native-epoll && mvn install -DskipTests
cd ../common && mvn install -DskipTests
cd ../all && mvn install -DskipTests
cp $wdir/netty/transport-native-epoll/target/native-build/target/lib/libnetty_transport_native_epoll_ppcle_64.so /usr/lib/

# Install netty-tcnative 2.0.63 (for Cassandra 4.0 bundled libs)
cd $wdir
mkdir -p netty58 && cd netty58
git clone https://github.com/netty/netty-tcnative.git
cd netty-tcnative
git checkout netty-tcnative-parent-2.0.63.Final
sed -i "s#<module>boringssl-static</module>##g" pom.xml
mvn install -DskipTests
mkdir -p $wdir/$PACKAGE_NAME/management-api-server/.cassandra-bin/apache-cassandra-4.0.19/lib/
cp $wdir/netty58/netty-tcnative/openssl-static/target/netty-tcnative-openssl-static-2.0.63.Final.jar \
    $wdir/$PACKAGE_NAME/management-api-server/.cassandra-bin/apache-cassandra-4.0.19/lib/netty-tcnative-boringssl-static-2.0.36.Final.jar

# Install netty 4.1.58 (for Cassandra 4.0 bundled libs)
cd $wdir/netty58
git clone https://github.com/netty/netty.git
cd netty
git checkout netty-4.1.58.Final
cd transport-native-unix-common && mvn install -DskipTests
cd ../transport-native-epoll && mvn install -DskipTests
cd ../common && mvn install -DskipTests
cd ../all && mvn install -DskipTests
cp $wdir/netty58/netty/all/target/netty-all-4.1.58.Final.jar \
    $wdir/$PACKAGE_NAME/management-api-server/.cassandra-bin/apache-cassandra-4.0.19/lib/netty-all-4.1.58.Final.jar

# Unit and integration tests
cd $wdir/$PACKAGE_NAME
podman tag cr.k8ssandra.io/k8ssandra/cass-management-api:4.1.11 mgmtapi-dockerfile-4.1.ubi-test:latest
rm -rf ./management-api-agent-common/src/test/java/io/k8ssandra/metrics/  # Metrics not supported on power
mvn integration-test -Drun4.1testsUBI=true

# Conclude
set +ex
echo "Build and tests Successful!"
echo "Image tag: cr.k8ssandra.io/k8ssandra/cass-management-api:4.1.11"