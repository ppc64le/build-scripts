#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package	    : camel-quarkus
# Version	    : main
# Source repo	: https://github.com/apache/camel-quarkus.git
# Tested on	    : UBI 8.5
# Language      : java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Shreya Kajbaje <Shreya.Kajbaje@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Install dependencies
yum -y update && yum install -y git wget java-17-openjdk-devel tar
JDK_PATHS=$(compgen -G '/usr/lib/jvm/java-17-openjdk-*')
export JAVA_HOME=${JDK_PATHS%$'\n'*}
export PATH=$JAVA_HOME/bin:$PATH

# Install maven
wget http://archive.apache.org/dist/maven/maven-3/3.8.4/binaries/apache-maven-3.8.4-bin.tar.gz
tar -zxf apache-maven-3.8.4-bin.tar.gz
cp -R apache-maven-3.8.4 /usr/local
ln -s /usr/local/apache-maven-3.8.4/bin/mvn /usr/bin/mvn

#-------------------------------Camel Build & Tests-------------------------------

PACKAGE_NAME=camel
PACKAGE_VERSION=camel-4.2.0
PACKAGE_URL=https://github.com/apache/camel.git

export MAVEN_PARAMS="-B -e -fae -V -Dnoassembly -Dmaven.compiler.fork=true -Dsurefire.rerunFailingTestsCount=2 -Dfailsafe.rerunFailingTestsCount=1"

# Clone git repository
if ! git clone $PACKAGE_URL; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
fi

cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

# Build
if ! ./mvnw -U $MAVEN_PARAMS -Dskip.camel.maven.plugin.tests -Dquickly clean install; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
fi

# Test
if ! ./mvnw $MAVEN_PARAMS -Darchetype.test.skip -Dmaven.test.failure.ignore=true -Dcheckstyle.skip=true verify -pl '!docs'; then
    echo "------------------$PACKAGE_NAME:test_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 2
fi

#resolves camel artifacts dependency from local maven repo 
mvn dependency:get -Dartifact=org.apache.camel:camel-buildtools:4.3.0-SNAPSHOT -o -DrepoUrl=file://~/.m2/repository

#-------------------------------Camel-Spring-boot Build & Tests-------------------------------

PACKAGE_NAME=camel-spring-boot
PACKAGE_VERSION=camel-spring-boot-4.2.0
PACKAGE_URL=https://github.com/apache/camel-spring-boot.git

#export MAVEN_PARAMS='-U -B -e -fae -V -Dmaven.repo.local=/home/.m2/repository -Dmaven.compiler.fork=true'

# Clone git repository
if ! git clone $PACKAGE_URL; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
fi

cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

# Build
if ! ./mvnw $MAVEN_PARAMS -Dmaven.test.failure.ignore=true -Dmaven.repo.local=/home/.m2/repository clean install; then
    echo "------------------$PACKAGE_NAME:build_fails & test_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
fi

#-------------------------------Camel-quarkus Build & Tests-------------------------------

PACKAGE_NAME=camel-quarkus
PACKAGE_VERSION=${1:-main}
PACKAGE_URL=https://github.com/apache/camel-quarkus.git

# Clone git repository
if ! git clone $PACKAGE_URL; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
fi

cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

# Build
if ! ./mvnw -Dmaven.test.failure.ignore=true -Dmaven.repo.local=/home/.m2/repository clean install; then
    echo "------------------$PACKAGE_NAME:build_fails & test_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
fi
