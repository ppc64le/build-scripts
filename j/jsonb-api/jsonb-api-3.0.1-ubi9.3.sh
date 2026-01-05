#!/bin/bash -ex
# --------------------------------------------------------------------------------------------
#
# Package       : jsonb-api
# Version       : 3.0.1
# Source repo   : https://github.com/jakartaee/jsonb-api.git
# Tested on     : UBI 9.3 (docker)
# Language      : Java
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Prachi Gaonkar <Prachi.Gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# --------------------------------------------------------------------------------------------


PACKAGE_NAME=jsonb-api
PACKAGE_VERSION=${1:-3.0.1}
PACKAGE_URL=https://github.com/jakartaee/jsonb-api.git
WDIR=$(pwd)
MAVEN_VERSION=${2:-3.9.9}
API_BASE_ARTIFACT_PATH=${WDIR}${PACKAGE_NAME}/api/target/jakarta.json.bind
TCK_BASE_ARTIFACT_PATH=${WDIR}${PACKAGE_NAME}/tck/target/jakarta.json.bind
API_ARTIFACT_PATH=${API_BASE_ARTIFACT_PATH}-api-${PACKAGE_VERSION}.jar
TCK_ARTIFACT_PATH=${TCK_BASE_ARTIFACT_PATH}-tck-3.0.0-SNAPSHOT.jar

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install -y git wget java-17-openjdk-devel

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$PATH:$JAVA_HOME/bin

#Install maven
wget https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
tar -zxf apache-maven-${MAVEN_VERSION}-bin.tar.gz
cp -R apache-maven-${MAVEN_VERSION} /usr/local
ln -s /usr/local/apache-maven-${MAVEN_VERSION}/bin/mvn /usr/bin/mvn

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! cd api && mvn clean install -Pstaging -B ; then
       echo "------------------$PACKAGE_NAME: API compilation Fails---------------------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | API compilation Fails"
       exit 1
fi

# Api Test
if ! mvn test ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_api_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_api_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success for api"
    echo "API Artifact built at location:  ${API_ARTIFACT_PATH}"
fi

	  
if ! cd ../tck && mvn clean install -Pstaging -B ; then
       echo "------------------$PACKAGE_NAME: TCK test compilation Fails---------------------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | TCK test compilations fails"
       exit 1
fi

# TCK Test
if ! mvn test ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_tck_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_tck_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success for tck"
    echo "TCK Artifact built at location:  ${TCK_ARTIFACT_PATH}"
fi


if ! cd ../docs && mvn clean install -Pstaging -B ; then
       echo "------------------$PACKAGE_NAME: Javadoc compilation---------------------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Javadoc compilation Fails"
       exit 1
fi

# docs Test
if ! mvn test ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_docs_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_docs_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success for docs"
fi

if ! cd ../spec && mvn clean install -Pstaging -B; then
       echo "------------------$PACKAGE_NAME:  Generating specification---------------------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |   Generating specification"
       exit 1
fi

# spec Test
if ! mvn test ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_docs_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_spec_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success for specs"
fi