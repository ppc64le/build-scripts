#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : neo4j-migrations
# Version          : 2.13.3
# Source repo      : https://github.com/michael-simons/neo4j-migrations
# Tested on	   : UBI:9.3
# Language         : Java
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : vinodk99 <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=neo4j-migrations
PACKAGE_VERSION=${1:-2.13.3}
PACKAGE_URL=https://github.com/michael-simons/neo4j-migrations

yum install git wget gcc gcc-c++ java-21-openjdk java-21-openjdk-devel java-21-openjdk-headless -y

export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH=$PATH:$JAVA_HOME
    
wget https://archive.apache.org/dist/maven/maven-3/3.8.7/binaries/apache-maven-3.8.7-bin.tar.gz
tar -zxf apache-maven-3.8.7-bin.tar.gz
cp -R apache-maven-3.8.7 /usr/local
ln -s /usr/local/apache-maven-3.8.7/bin/mvn /usr/bin/mvn

git clone $PACKAGE_URL $PACKAGE_NAME
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! ./mvnw -Dmigrations.test-only-latest-neo4j=true --no-transfer-progress clean install -pl -:neo4j-migrations,-:neo4j-migrations-quarkus-deployment,-:neo4j-migrations-quarkus-integration-tests,-:neo4j-migrations-formats-csv,-:neo4j-migrations-maven-plugin,-:neo4j-migrations-test-results; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! ./mvnw test -pl -:neo4j-migrations,-:neo4j-migrations-quarkus-deployment,-:neo4j-migrations-quarkus-integration-tests,-:neo4j-migrations-formats-csv,-:neo4j-migrations-maven-plugin,-:neo4j-migrations-test-results; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
