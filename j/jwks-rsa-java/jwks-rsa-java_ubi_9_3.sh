#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : jwks-rsa-java
# Version          : 0.22.1
# Source repo      : https://github.com/auth0/jwks-rsa-java
# Tested on        : UBI:9.3
# Language         : Java
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Stuti Wali <Stuti.Wali@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

set -e
PACKAGE_NAME="jwks-rsa-java"
PACKAGE_URL="https://github.com/auth0/jwks-rsa-java"
PACKAGE_VERSION=${1:-0.22.1}
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
HOME_DIR=$PWD

#installing required dependencies
echo "installing dependencies from system repo..."
dnf install -y git make gcc gcc-c++ libtool file diffutils bc wget initscripts

#Install temurin8-binaries
wget https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u302-b08/OpenJDK8U-jdk_ppc64le_linux_hotspot_8u302b08.tar.gz
tar -C /usr/local -xzf OpenJDK8U-jdk_ppc64le_linux_hotspot_8u302b08.tar.gz
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF8" 
export JAVA_HOME=/usr/local/jdk8u302-b08/ 
export PATH=$PATH:/usr/local/jdk8u302-b08/bin 
ln -sf /usr/local/jdk8u302-b08/bin/java /usr/bin/ 
java -version

# Cloning the repository from remote to local
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


#build
if ! ./gradlew clean build -x test -x JAVADOC ; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

#test
if ! ./gradlew test; then
    echo "------------------$PACKAGE_NAME:Build_success_and_Test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Fail |  Build_Success_and_Test_fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Build_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi

