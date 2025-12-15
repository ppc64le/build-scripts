#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : rabbitmq-java-client
# Version       : v5.22.0
# Source repo   : https://github.com/rabbitmq/rabbitmq-java-client
# Tested on     : UBI 9.3
# Language      : Java, Others
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Pratibh Goshi<pratibh.goshi@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
# This should be run in the privileged mode
set -e

PACKAGE_NAME=rabbitmq-java-client
PACKAGE_VERSION=${1:-v5.22.0}
PACKAGE_URL=https://github.com/rabbitmq/rabbitmq-java-client



# install tools and dependent packages
yum install -y git wget unzip sudo make gcc gcc-c++ cmake python3 python3-devel docker
pip3 install simplejson
ln -sf /usr/bin/python3 /usr/bin/python

# setup java environment
yum install -y java java-devel

export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-)(?=.*ppc64le)') 
# update the path env. variable
export PATH=$PATH:$JAVA_HOME/bin



# install maven
MAVEN_VERSION=${MAVEN_VERSION:-3.8.8}
wget https://downloads.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz
tar -C /usr/local/ -xzf apache-maven-$MAVEN_VERSION-bin.tar.gz
mv /usr/local/apache-maven-$MAVEN_VERSION /usr/local/maven

export M2_HOME=/usr/local/maven

# update the path env. variable
export PATH=$PATH:$M2_HOME/bin

# Commenting out below command, as docker inside docker is disabled in currency.
# Start RabbitMQ service 
# docker run -d --hostname my-rabbit --name some-rabbit rabbitmq:3

# clone and checkout specified version
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
make deps

#Build
./mvnw clean install -DskipTests 
if [ $? != 0 ]
then
  echo "Build failed for $PACKAGE_NAME-$PACKAGE_VERSION"
  exit 1
fi

# Commenting out below code as tests requires docker container, and we can not install docker within container in currency. 
# Test
# ./mvnw verify -P '!setup-test-cluster' -Drabbitmqctl.bin=DOCKER:rabbitmq -Dit.test=ClientTestSuite,FunctionalTestSuite,ServerTestSuite
# if [ $? != 0 ]
# then
#  echo "Test failed for $PACKAGE_NAME-$PACKAGE_VERSION"
#  exit 1
# fi

# Expected Result
# [INFO] Results:
# [INFO]
# [WARNING] Tests run: 654, Failures: 0, Errors: 0, Skipped: 22
# [INFO]
# [INFO]
# [INFO] --- failsafe:3.5.0:verify (verify) @ amqp-client ---
# [INFO] ------------------------------------------------------------------------
# [INFO] BUILD SUCCESS
# [INFO] ------------------------------------------------------------------------
# [INFO] Total time:  10:22 min
# [INFO] Finished at: 2024-11-06T01:27:48-05:00
# [INFO] ------------------------------------------------------------------------

exit 0