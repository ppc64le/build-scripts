#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : rabbitmq-java-client
# Version       : v5.17.0
# Source repo   : https://github.com/rabbitmq/rabbitmq-java-client
# Tested on     : UBI: 8.7
# Language      : Java
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e
PACKAGE_NAME=rabbitmq-java-client
PACKAGE_URL=https://github.com/rabbitmq/rabbitmq-java-client

#Default tag rabbitmq-java-client
if [ -z "$1" ]; then
  export PACKAGE_VERSION="v5.17.0"
else
  export PACKAGE_VERSION="$1"
fi

#install docker 
dnf install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo docker-compose-plugin
dnf install -y docker-ce docker-ce-cli containerd.io
systemctl enable docker
#Commenting out below command, as docker inside docker is disabled in currency.
#systemctl start docker
#docker run -d --rm --name rabbitmq -p 5672:5672 rabbitmq

# install tools and dependent packages
yum install -y git wget zip unzip tar make java-1.8.0-openjdk-devel.ppc64le gcc gcc-c++ python39 python39-devel 
pip3 install simplejson
ln -sf /usr/bin/python3 /usr/bin/python

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8"
export RABBIT_VSN=0.0.0

#installing maven 3.8.6
wget http://archive.apache.org/dist/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz
tar -C /usr/local/ -xzvf apache-maven-3.8.6-bin.tar.gz
rm -rf tar xzvf apache-maven-3.8.6-bin.tar.gz
mv /usr/local/apache-maven-3.8.6 /usr/local/maven
export M2_HOME=/usr/local/maven
export PATH=$PATH:$M2_HOME/bin

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
      rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Removed existing package if any"
fi

# Cloning the repository 
git clone $PACKAGE_URL
cd ${PACKAGE_NAME}
git checkout $PACKAGE_VERSION
make deps

#Build and test package
if ! mvn clean install -DskipTests; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
fi

#Commenting out below code as tests requires docker container, and we can not install docker within container in currency. 
#if ! ./mvnw verify -P '!setup-test-cluster' -Drabbitmqctl.bin=DOCKER:rabbitmq -Dit.test=ClientTestSuite,FunctionalTestSuite,ServerTestSuite; then
#    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
#    echo "$PACKAGE_URL $PACKAGE_NAME"
#    exit 2
#fi

