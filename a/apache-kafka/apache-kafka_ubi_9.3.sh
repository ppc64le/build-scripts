#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package               : kafka
# Version               : 3.9.0
# Source repo           : https://github.com/apache/kafka
# Tested on             : UBI:9.3
# Language              : Java
# Travis-Check          : True
# Script License        : Apache License 2.0 or later
# Maintainer            : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_VERSION=${1:-3.9.0}
PACKAGE_NAME=kafka
PACKAGE_URL=https://github.com/apache/kafka

yum install -y git make wget gcc-c++

wget https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.9%2B9/OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.9_9.tar.gz
tar -C /usr/local -zxf OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.9_9.tar.gz
export JAVA_HOME=/usr/local/jdk-17.0.9+9
export JAVA17_HOME=/usr/local/jdk-17.0.9+9
export PATH=$PATH:/usr/local/jdk-17.0.9+9/bin
ln -sf /usr/local/jdk-17.0.9+9/bin/java /usr/bin
rm -f OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.9_9.tar.gz

# Clone git repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

if ! ./gradlew jar; then
       echo "------------------$PACKAGE_NAME:Build_fails---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
       exit 1
fi

if ! ./gradlew unitTest --continue -PtestLoggingEvents=started,passed,skipped,failed -PignoreFailures=true -PmaxParallelForks=2 ; then
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
