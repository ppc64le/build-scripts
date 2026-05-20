#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : kafka
# Version       : v4.1.0
# Source repo   : https://github.com/apache/kafka
# Tested on     : UBI:9.7
# Language      : Java
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Veenious D Geevarghese <Veenious.Geevarghese@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=kafka
PACKAGE_VERSION=${1:-'4.1.0'}
PACKAGE_URL=https://github.com/apache/kafka.git

BITNAMI_COMMIT=${BITNAMI_COMMIT:-be4c353}
GO_VERSION=${GO_VERSION:-1.26.3}

BUILD_HOME=$(pwd)
SCRIPT_PATH=$(dirname "$(realpath "$0")")
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

# ----------------------------------------------------------------------------
# Install system dependencies
# ----------------------------------------------------------------------------
yum update -y
yum install -y \
    git wget tar gcc gcc-c++ make \
    java-17-openjdk-devel.ppc64le \
    libtool file diffutils \
    acl ca-certificates curl-minimal gzip glibc \
    procps-ng zlib xz unzip zip findutils which
yum upgrade -y --allowerasing
yum upgrade -y libcap vim-minimal
yum clean all

# ----------------------------------------------------------------------------
# Install Go (fixes stdlib CVEs: CVE-2025-68121, CVE-2025-58183, etc.)
# ----------------------------------------------------------------------------
wget -q "https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz"
tar -C /usr/local -xzf "go${GO_VERSION}.linux-ppc64le.tar.gz"
rm "go${GO_VERSION}.linux-ppc64le.tar.gz"
export PATH="/usr/local/go/bin:$PATH"
go version

# ----------------------------------------------------------------------------
# Build wait-for-port from source
# ----------------------------------------------------------------------------
git clone https://github.com/bitnami/wait-for-port "$BUILD_HOME/wait-for-port"
cd "$BUILD_HOME/wait-for-port"
git checkout v1.0.10
go build .

# ----------------------------------------------------------------------------
# Assemble Bitnami prebuildfs
# ----------------------------------------------------------------------------
git clone https://github.com/bitnami/containers "$BUILD_HOME/containers"
cd "$BUILD_HOME/containers"
git checkout "$BITNAMI_COMMIT"

cd "$BUILD_HOME/containers/bitnami/kafka/4.1/debian-12"
wget "https://downloads.bitnami.com/files/stacksmith/kafka-${PACKAGE_VERSION}-0-linux-amd64-debian-12.tar.gz" || true
if [ -f "kafka-${PACKAGE_VERSION}-0-linux-amd64-debian-12.tar.gz" ]; then
    tar -xvf "kafka-${PACKAGE_VERSION}-0-linux-amd64-debian-12.tar.gz"
    mkdir -p prebuildfs/opt/bitnami/kafka/config
    if [ -d "kafka-${PACKAGE_VERSION}-linux-amd64-debian-12/files/kafka/config" ]; then
        cp -r "kafka-${PACKAGE_VERSION}-linux-amd64-debian-12/files/kafka/config/"* \
           prebuildfs/opt/bitnami/kafka/config/
    fi
fi

# Copy prebuildfs and rootfs into place
cp -r prebuildfs/. /
cp -r rootfs/. /

# ----------------------------------------------------------------------------
# Clone Kafka
# ----------------------------------------------------------------------------
if ! git clone "$PACKAGE_URL" "$BUILD_HOME/kafka"; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Clone_Fails"
    exit 0
fi

cd "$BUILD_HOME/kafka"
git checkout "$PACKAGE_VERSION"
echo "Checked out Kafka version: $PACKAGE_VERSION"
git describe --tags

# ----------------------------------------------------------------------------
# Set Java environment
# ----------------------------------------------------------------------------
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-17)(?=.*ppc64le)')
export PATH=$JAVA_HOME/bin:$PATH
java -version

# ----------------------------------------------------------------------------
# Create Gradle dependency overrides for CVE fixes
# ----------------------------------------------------------------------------
cat > init.gradle << 'EOF'
allprojects {
    configurations.all {
        resolutionStrategy {
            force 'commons-io:commons-io:2.21.0'
            force 'org.apache.httpcomponents.client5:httpclient5:5.6.1'
            force 'org.bouncycastle:bcpg-jdk18on:1.84'
            force 'org.bouncycastle:bcprov-jdk18on:1.84'
            force 'org.codehaus.plexus:plexus-utils:4.0.3'
            force 'org.eclipse.jetty:jetty-http:12.0.33'
            force 'org.eclipse.jetty:jetty-server:12.0.33'
            force 'org.eclipse.jetty:jetty-io:12.0.33'
            force 'org.eclipse.jetty:jetty-util:12.0.33'
            force 'org.eclipse.jetty:jetty-client:12.0.33'
        }
    }
}
EOF

# ----------------------------------------------------------------------------
# Build Kafka
# ----------------------------------------------------------------------------
if ! ./gradlew jar -x test --init-script init.gradle; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Build_Fails"
    exit 1
fi

# ----------------------------------------------------------------------------
# Collect Kafka binaries and libraries
# ----------------------------------------------------------------------------
mkdir -p /root/kafka/bin /root/kafka/libs /root/kafka/config

cp -r "$BUILD_HOME/kafka/bin/"* /root/kafka/bin/
cp -r "$BUILD_HOME/kafka/config/"* /root/kafka/config/
find "$BUILD_HOME/kafka" -path "*/build/libs/*.jar" -type f -exec cp {} /root/kafka/libs/ \;
find "$BUILD_HOME/kafka" -path "*/build/dependant-libs/*.jar" -type f -exec cp {} /root/kafka/libs/ \; 2>/dev/null || true
find "$BUILD_HOME/kafka" -path "*/build/dependant-libs-*/*.jar" -type f -exec cp {} /root/kafka/libs/ \; 2>/dev/null || true
find /root/.gradle/caches/modules-2/files-2.1 -name "*.jar" -exec cp {} /root/kafka/libs/ \; 2>/dev/null || true

echo "Total JARs before cleanup: $(ls -1 /root/kafka/libs/*.jar | wc -l)"

# ----------------------------------------------------------------------------
# Remove vulnerable JAR versions
# ----------------------------------------------------------------------------
cd /root/kafka/libs
rm -f commons-io-2.11.0.jar commons-io-2.8.0.jar || true
rm -f httpclient5-5.6.jar || true
rm -f bcpg-jdk18on-1.71.jar bcpg-jdk18on-1.83.jar || true
rm -f bcprov-jdk18on-1.71.jar bcprov-jdk18on-1.83.jar bcprov-jdk15on-1.56.jar || true
rm -f plexus-utils-4.0.2.jar plexus-utils-3.*.jar || true
rm -f jetty-http-12.0.22.jar jetty-server-12.0.22.jar jetty-io-12.0.22.jar || true
rm -f jetty-util-12.0.22.jar jetty-client-12.0.22.jar || true
rm -f jackson-core-2.14.2.jar jackson-databind-2.14.2.jar jackson-annotations-2.14.2.jar || true
rm -f jackson-dataformat-yaml-2.14.2.jar jackson-module-afterburner-2.14.2.jar jackson-module-blackbird-2.14.2.jar || true
rm -f ehcache-2.10.4.jar || true
rm -f h2-2.1.214.jar || true
rm -f xstream-1.4.20.jar || true
rm -f snakeyaml-1.33.jar || true
rm -f lz4-java-1.8.0.jar || true
rm -f mina-core-2.0.16.jar || true
rm -f velocity-engine-core-2.3.jar || true
rm -f commons-beanutils-1.9.4.jar || true

ls -lh /root/kafka/libs/
echo "Total JARs after cleanup: $(ls -1 /root/kafka/libs/*.jar | wc -l)"

# ----------------------------------------------------------------------------
# Install runtime layout under /opt/bitnami
# ----------------------------------------------------------------------------
chmod g+rwX /opt/bitnami
mkdir -p /opt/bitnami/common/bin /opt/bitnami/kafka /opt/bitnami/java/bin

# Set Java environment for runtime (dynamically detect)
REAL_JAVA_HOME=$(ls -d /usr/lib/jvm/java-17-openjdk-* | head -1)
echo "export JAVA_HOME=$REAL_JAVA_HOME" >> /etc/profile.d/java.sh
echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> /etc/profile.d/java.sh

# Create Java symlinks
ln -s "$REAL_JAVA_HOME" /opt/bitnami/java/jre
ln -s "$REAL_JAVA_HOME/bin/java" /opt/bitnami/java/bin/java

# Copy wait-for-port utility
cp "$BUILD_HOME/wait-for-port/wait-for-port" /opt/bitnami/common/bin/wait-for-port
chmod +x /opt/bitnami/common/bin/wait-for-port

# Copy Kafka artifacts
cp -r /root/kafka/bin/. /opt/bitnami/kafka/bin/
cp -r /root/kafka/libs/. /opt/bitnami/kafka/libs/
cp -r /root/kafka/config/. /opt/bitnami/kafka/config/

# Set executable permissions
chmod +x /opt/bitnami/kafka/bin/*.sh

# Create entrypoint symlinks
ln -sf /opt/bitnami/scripts/kafka/entrypoint.sh /entrypoint.sh
ln -sf /opt/bitnami/scripts/kafka/run.sh /run.sh

# Run postunpack scripts
/opt/bitnami/scripts/java/postunpack.sh
/opt/bitnami/scripts/kafka/postunpack.sh
chmod g+rwX /opt/bitnami

# ----------------------------------------------------------------------------
# Cleanup
# ----------------------------------------------------------------------------
yum clean all
rm -rf /var/cache/yum /var/tmp/*

# ----------------------------------------------------------------------------
# Set environment variables
# ----------------------------------------------------------------------------
export HOME="/"
export OS_ARCH="ppc64le"
export OS_FLAVOUR="rhel9"
export OS_NAME="linux"
export JAVA_HOME="/opt/bitnami/java"
export PATH="/opt/bitnami/java/bin:/opt/bitnami/common/bin:/opt/bitnami/kafka/bin:$PATH"
export APP_VERSION="$PACKAGE_VERSION"
export BITNAMI_APP_NAME="kafka"
export IMAGE_REVISION="0"

echo "------------------$PACKAGE_NAME:install_&_build_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Build_and_Install_Success"
exit 0


