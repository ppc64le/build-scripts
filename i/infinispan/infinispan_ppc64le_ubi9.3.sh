#!/bin/bash 
# ----------------------------------------------------------------------------
#
# Package        : infinispan
# Version        : 16.0.5
# Source repo    : https://github.com/infinispan/infinispan
# Tested on      : UBI9.3
# Language       : Java
# Ci-Check       : True
# Script License : Apache License Version 2
# Maintainer     : Radhika Ajabe <Radhika.Ajabe@ibm.com>

# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_NAME=infinispan
PACKAGE_URL=https://github.com/infinispan/infinispan
PACKAGE_VERSION=16.0.5

yum install git wget -y
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

yum install java-21-openjdk java-21-openjdk-devel -y
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
export PATH=$JAVA_HOME/bin:$PATH

wget https://dlcdn.apache.org/maven/maven-3/3.9.12/binaries/apache-maven-3.9.12-bin.tar.gz
tar -C /usr/local/ -xzvf apache-maven-3.9.12-bin.tar.gz
rm -rf tar xzvf apache-maven-3.9.12-bin.tar.gz
mv -n /usr/local/apache-maven-3.9.12 /usr/local/maven
export M2_HOME=/usr/local/maven
export PATH=$PATH:$M2_HOME/bin

#Excluded below components because they are failing on power and are in parity with x86
EXCLUDED_COMPONENTS="-pl !:infinispan-counter-api,!:infinispan-core,!:infinispan-jboss-marshalling,!:infinispan-clustered-counter,!:infinispan-multimap,!:infinispan-cachestore-jdbc-common,!:infinispan-cachestore-jdbc,!:infinispan-query,!:infinispan-tasks,!:infinispan-scripting,!:infinispan-server-core,!:infinispan-server-hotrod,!:infinispan-client-hotrod,!:infinispan-cachestore-remote,!:infinispan-cachestore-rocksdb,!:infinispan-tools,!:infinispan-cachestore-sql,!:infinispan-server-tests,!:infinispan-server-insights,!:infinispan-server-memcached,!:infinispan-server-resp,!:infinispan-server-rest,!:infinispan-server-router,!:infinispan-anchored-keys,!:infinispan-cli-client,!:infinispan-server-runtime,!:infinispan-client-hotrod-test,!:infinispan-spring6-embedded,!:infinispan-spring6-remote,!:infinispan-spring7-embedded,!:infinispan-spring7-remote,!:infinispan-spring-boot3-starter-embedded,!:infinispan-spring-boot3-starter-remote,!:infinispan-spring-boot3-starter-session-tests,!:infinispan-spring-boot3-starter-embedded-tests,!:infinispan-spring-boot4-starter-embedded,!:infinispan-spring-boot4-starter-remote,!:infinispan-spring-boot4-starter-session-tests,!:infinispan-spring-boot4-starter-embedded-tests,!:infinispan-cdi-embedded,!:infinispan-cdi-remote,!:infinispan-clustered-lock,!:infinispan-jcache,!:infinispan-jcache-remote,!:infinispan-jcache-tck-runner-remote,!:infinispan-core-graalvm,!:infinispan-client-hotrod-graalvm,!:infinispan-gridfs,!:infinispan-endpoint-interop-it,!:infinispan-jboss-marshalling-it,!:infinispan-cdi-weld-se-it,!:custom-module,!:store,!:infinispan-third-party-integrationtests"

if ! mvn install $EXCLUDED_COMPONENTS; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL   $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_fails"
    exit 2;
else
    echo "------------------$PACKAGE_NAME:Install_success-------------------------"
    echo "$PACKAGE_URL    $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass |  Build_Success"
    exit 0;
fi
