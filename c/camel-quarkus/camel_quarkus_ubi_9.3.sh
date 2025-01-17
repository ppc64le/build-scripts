#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : camel-quarkus
# Version          : 3.17.0
# Source repo      : https://github.com/apache/camel-quarkus
# Tested on        : UBI:9.3
# Language         : Java
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Prasanna Marathe<prasanna.marathe@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=camel-quarkus
#package 3.17 is latest version however build is failing for both x86 platform
PACKAGE_VERSION=${1:-main}
PACKAGE_URL=https://github.com/apache/camel-quarkus

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

#install java17
yum -y update && yum install -y git wget java-17-openjdk-devel tar
JDK_PATHS=$(compgen -G '/usr/lib/jvm/java-17-openjdk-*')
export JAVA_HOME=${JDK_PATHS%$'\n'*}
export PATH=$JAVA_HOME/bin:$PATH

#install maven
wget https://archive.apache.org/dist/maven/maven-3/3.9.7/binaries/apache-maven-3.9.7-bin.tar.gz
tar -zxf apache-maven-3.9.7-bin.tar.gz
cp -R apache-maven-3.9.7 /usr/local
ln -s /usr/local/apache-maven-3.9.7/bin/mvn /usr/bin/mvn

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Build
#at present only BUILD is supported as TEST is failing because mutiple came compoennets does not have ppc64l3 support
#export MAVEN_OPTS="-Xmx2048m -Xms1024m  -Djava.awt.headless=true"
#export MAVEN_PARAMS="-B -e -fae -V -Dnoassembly -Dmaven.compiler.fork=true -Dsurefire.rerunFailingTestsCount=2 -Dfailsafe.rerunFailingTestsCount=1"
if ! mvn clean install -Dquickly; then
    echo "------------------$PACKAGE_NAME:build fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:build success---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass|  Build_success"
    exit 0
fi
