#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : directory-server
# Version          : 2.0.0.AM27
# Source repo      : https://github.com/apache/directory-server
# Tested on        : UBI:9.3
# Language         : Java
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_VERSION=${1:-2.0.0.AM27}
PACKAGE_NAME=directory-server
PACKAGE_URL=https://github.com/apache/directory-server

OS_NAME=$(cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f2 | tr -d '"')

yum install -y git wget tar openssl-devel freetype fontconfig

wget https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.22%2B7/OpenJDK11U-jdk_ppc64le_linux_hotspot_11.0.22_7.tar.gz
tar -C /usr/local -xzf OpenJDK11U-jdk_ppc64le_linux_hotspot_11.0.22_7.tar.gz
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF8"
export JAVA_HOME=/usr/local/jdk-11.0.22+7/
export PATH=$PATH:/usr/local/jdk-11.0.22+7/bin
ln -sf /usr/local/jdk-11.0.22+7/bin/java /usr/bin/java
rm -rf OpenJDK11U-jdk_ppc64le_linux_hotspot_11.0.22_7.tar.gz

# Install Maven
wget https://archive.apache.org/dist/maven/maven-3/3.9.1/binaries/apache-maven-3.9.1-bin.tar.gz
tar -zxf apache-maven-3.9.1-bin.tar.gz
cp -R apache-maven-3.9.1 /usr/local
ln -s /usr/local/apache-maven-3.9.1/bin/mvn /usr/bin/mvn

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Build and test.
if ! mvn -U clean install -Djava.awt.headless=true -fae -B -Dskiptests=true; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! mvn -U clean install -Djava.awt.headless=true -fae -B; then
    echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_and_Test_fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi
