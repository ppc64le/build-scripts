#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : keycloak
# Version          : 25.0.5
# Source repo      : https://github.com/keycloak/keycloak
# Tested on        : UBI:9.3
# Language         : Go
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
PACKAGE_NAME=keycloak
PACKAGE_VERSION=${1:-25.0.5}
PACKAGE_URL=https://github.com/keycloak/keycloak

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install -y git make wget gcc-c++

#install temurin java21
wget https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.2%2B13/OpenJDK21U-jdk_ppc64le_linux_hotspot_21.0.2_13.tar.gz
tar -C /usr/local -zxf OpenJDK21U-jdk_ppc64le_linux_hotspot_21.0.2_13.tar.gz
export JAVA_HOME=/usr/local/jdk-21.0.2+13/
export JAVA21_HOME=/usr/local/jdk-21.0.2+13/bin/
export PATH=$PATH:/usr/local/jdk-21.0.2+13/bin/
ln -sf /usr/local/jdk-21.0.2+13/bin/java /usr/bin/
rm -rf OpenJDK21U-jdk_ppc64le_linux_hotspot_21.0.2_13.tar.gz

#install maven
wget https://archive.apache.org/dist/maven/maven-3/3.9.7/binaries/apache-maven-3.9.7-bin.tar.gz
tar -zxf apache-maven-3.9.7-bin.tar.gz
cp -R apache-maven-3.9.7 /usr/local
ln -s /usr/local/apache-maven-3.9.7/bin/mvn /usr/bin/mvn

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

export MAVEN_OPTS="-Xmx2048m -Xms1024m  -Djava.awt.headless=true"

if ! mvn clean install -DskipTests=true -pl -:keycloak-admin-ui,-:keycloak-account-ui,-:keycloak-ui-shared ; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi

echo "Testing Unit Tests"
SEP=""
PROJECTS=""
for i in `find -name '*Test.java' -type f | egrep -v './(testsuite|quarkus|docs|test-poc)/' | sed 's|/src/test/java/.*||' | sort | uniq | sed 's|./||'`; do
    PROJECTS="$PROJECTS$SEP$i"
    SEP=","
done

if ! ./mvnw test -pl "$PROJECTS" -am -pl -:keycloak-services; then
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
