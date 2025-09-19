#!/bin/bash 
# ----------------------------------------------------------------------------
#
# Package        : camel-karaf
# Version        : camel-karaf-4.10.3
# Source repo    : https://github.com/apache/camel-karaf.git
# Tested on      : RHEL 9.1
# Language       : Java
# Travis-Check   : True
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

PACKAGE_NAME=camel-karaf
PACKAGE_URL=https://github.com/apache/camel-karaf
PACKAGE_VERSION=camel-karaf-4.10.3

yum install git wget -y
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

yum install java-17-openjdk java-17-openjdk-devel -y
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH

wget  https://dlcdn.apache.org/maven/maven-3/3.9.11/binaries/apache-maven-3.9.11-bin.tar.gz
tar -C /usr/local/  -xvzf apache-maven-3.9.11-bin.tar.gz
rm -rf tar xzvf apache-maven-3.9.11-bin.tar.gz
mv /usr/local/apache-maven-3.9.11 /usr/local/maven
export M2_HOME=/usr/local/maven
export PATH=$PATH:$M2_HOME/bin

#Excluded 26 components because ppc64le supported images are not available for them and excluded 5 components because they require a Docker environment.
EXCLUDED_COMPONENTS="-pl !:camel-amqp-test,!:camel-activemq-test,!:camel-arangodb-test,!:camel-aws2-iam-test,!:camel-aws2-kinesis-test,!:camel-aws2-s3-test,!:camel-aws2-ses-test,!:camel-aws2-sns-test,!:camel-aws2-sqs-test,!:camel-aws2-sts-test,!:camel-azure-storage-blob-test,!:camel-azure-storage-blob-test,!:camel-consul-test,!:camel-chatscript-test,!:camel-couchdb-test,!:camel-debezium-mongodb-test,!:camel-debezium-mysql-test,!:camel-debezium-postgres-test,!:camel-docker-test,!:camel-drill-test,!:camel-elasticsearch-test,!:camel-google-pubsub-test,!:camel-http-test,!:camel-influxdb2-test,!:camel-jms-test,!:camel-kafka-test,!:camel-leveldb-test,!:camel-mail-test,!:camel-paho-mqtt5-test,!:camel-spring-rabbitmq-test,!:camel-azure-storage-queue-test"

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
