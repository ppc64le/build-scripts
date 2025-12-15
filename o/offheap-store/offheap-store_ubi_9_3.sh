#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : offheap-store
# Version          : v2.5.6
# Source repo      : https://github.com/Terracotta-OSS/offheap-store
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
PACKAGE_NAME="offheap-store"
PACKAGE_URL="https://github.com/Terracotta-OSS/offheap-store"
PACKAGE_VERSION=${1:-v2.5.6}
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
HOME_DIR=$PWD
MAVEN_VERSION=3.9.6

#installing required dependencies
echo "installing dependencies from system repo..."
dnf install -y git make gcc gcc-c++ java-1.8.0-openjdk java-1.8.0-openjdk-devel libtool file diffutils bc wget initscripts
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-1.8.0)(?=.*ppc64le)')
export PATH=$JAVA_HOME/bin:$PATH
java -version 

#Install maven
wget https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
tar xvf apache-maven-${MAVEN_VERSION}-bin.tar.gz
rm -rf apache-maven-${MAVEN_VERSION}-bin.tar.gz
PATH=$CWD/apache-maven-${MAVEN_VERSION}/bin:$PATH

#copying toolchains.xml file to .m2 folder needed to build and test
wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/o/offheap-store/toolchains.xml
mkdir ~/.m2
cp toolchains.xml ~/.m2/

# Cloning the repository from remote to local
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#build
if ! ./mvnw clean install -DskipTests -Dfast -Djava.build.vendor=OpenJDK ; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

#test
if ! ./mvnw verify -DskipITs -Dfast -Djava.test.vendor=openjdk; then
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
