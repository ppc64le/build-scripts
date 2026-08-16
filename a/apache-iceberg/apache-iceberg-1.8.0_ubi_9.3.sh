#!/usr/bin/env bash
# -----------------------------------------------------------------
#
# Package	     : apache-iceberg
# Version	     : apache-iceberg-1.8.0
# Source repo	 : https://github.com/apache/iceberg
# Tested on	     : UBI 9.3
# Language       : Java
# Travis-Check   : false
# Script License : Apache License, Version 2 or later
# Maintainer	 : Onkar Kubal <onkar.kubal@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
# Note: In this script we are skipping following tests:
# ===== 1. iceberg-kafka-connect:iceberg-kafka-connect-runtime:integrationTest
#          This test requires confluentinc/cp-kafka ,confluentinc/cp-kafka-connect
#          docker iamges.Currently these images are not available for ppc64le.
#          This issue can be be solved by creating images for cp-kafka & cp-kafka-connect.
#          These images can be created from other images for which we don't have approval.
#          Hence we will be skipping
#          kafka-connect-runtime:integrationTest during testing.
#       2. iceberg-spark:iceberg-spark-3.5_2.12:test
#          This test is failing in group,with error message
#          'Gradle Test Executor 24' finished with non-zero exit value 137.
#          When tried to test individully it is passing. The command is as follows:
#          ./gradlew iceberg-spark:iceberg-spark-3.5_2.12:test --max-workers 4 --no-daemon
#
# ----------------------------------------------------------------------------
set -e 
PACKAGE_NAME=iceberg
SCRIPT_PACKAGE_VERSION=main
PACKAGE_VERSION=apache-iceberg-1.8.0
PACKAGE_VERSION_AZURE=${2:-3.33.0}
PACKAGE_URL=https://github.com/apache/${PACKAGE_NAME}.git
SCRIPT_PATH=$(dirname $(realpath $0))
BUILD_HOME=$(pwd)

# Install docker if not found
if ! [ $(command -v docker) ]; then
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
mkdir -p /etc/docker
touch /etc/docker/daemon.json
cat <<EOT > /etc/docker/daemon.json
{
"ipv6": true,
"fixed-cidr-v6": "2001:db8:1::/64",
"mtu": 1450
}
EOT
dockerd > /dev/null 2>&1 &
sleep 5
fi
# docker run hello-world

# Install deps
yum install -y git gcc gcc-c++ java-17-openjdk java-17-openjdk-devel nano
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH
echo "JAVA Version"
java --version

# Build ppc64le supported Azurite Image
cd $BUILD_HOME
git clone https://github.com/Azure/Azurite.git && cd Azurite
git checkout v${PACKAGE_VERSION_AZURE}
sed -i '5 a \\n#Add ppc64le dependencies \nRUN apk add python3 python3-dev g++ make pkgconfig libsecret-dev' Dockerfile
docker build -t mcr.microsoft.com/azure-storage/azurite .
docker tag mcr.microsoft.com/azure-storage/azurite:latest mcr.microsoft.com/azure-storage/azurite:${PACKAGE_VERSION_AZURE}
cd /

# Clone iceberg code
cd $BUILD_HOME
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME}
git pull -f
git checkout ${PACKAGE_VERSION}

# Apply patch
git apply $BUILD_HOME/${PACKAGE_VERSION}.patch

# Iceberg REST Catalog Adapter Test Fixture
./gradlew :iceberg-open-api:shadowJar
docker image rm -f apache/iceberg-rest-fixture && docker build -t apache/iceberg-rest-fixture -f docker/iceberg-rest-fixture/Dockerfile .

echo "List docker images:"
docker image ls

# docker compose -f kafka-connect/kafka-connect-runtime/docker/docker-compose.yml up -d

ret=0
# Invoke Build without Tests
./gradlew build -x test -x integrationTest || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "Build fail."
    exit 1
fi

echo "Build is successful."

ret=0
# Invoke Build with Unit and Integration tests (minus one task)
# ./gradlew iceberg-spark:iceberg-spark-3.5_2.12:test --max-workers 4 --no-daemon
# ./gradlew build || ret=$?
./gradlew build -x :iceberg-kafka-connect:iceberg-kafka-connect-runtime:integrationTest -x :iceberg-spark:iceberg-spark-3.5_2.12:test --max-workers 4 --no-daemon || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "Build with Tests fail."
    exit 2
fi

echo "Build with testcases successful."
ICEBERG_LIBS=$BUILD_HOME/${PACKAGE_NAME}/data/build/libs
echo "ICEBERG Libs is available at [$ICEBERG_LIBS]."
echo "The files are:"
ls $ICEBERG_LIBS