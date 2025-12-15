#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : HikariCP
# Version          : HikariCP-5.1.0
# Source repo      : https://github.com/brettwooldridge/HikariCP
# Tested on        : UBI:9.3
# Language         : Java
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in non-root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

PACKAGE_NAME=HikariCP
PACKAGE_URL=https://github.com/brettwooldridge/HikariCP
PACKAGE_VERSION=${1:-HikariCP-5.1.0}

yum install -y java-11-openjdk java-11-openjdk-devel java-11-openjdk-headless git wget
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$PATH:$JAVA_HOME/bin

#install maven
wget https://archive.apache.org/dist/maven/maven-3/3.9.7/binaries/apache-maven-3.9.7-bin.tar.gz
tar -zxf apache-maven-3.9.7-bin.tar.gz
cp -R apache-maven-3.9.7 /usr/local
ln -s /usr/local/apache-maven-3.9.7/bin/mvn /usr/bin/mvn

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! mvn clean package -DskipTests=true  ; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME::Build_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_Success"
    exit 0
fi

#Skipping tests because tests required docker to be installed in container.