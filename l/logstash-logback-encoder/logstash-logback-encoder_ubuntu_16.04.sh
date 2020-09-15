# ----------------------------------------------------------------------------
#
# Package	: logstash-logback-encoder
# Version	: 4.9
# Source repo	: https://github.com/logstash/logstash-logback-encoder
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

# Install dependencies.
sudo apt-get update -y
sudo apt-get install -y openjdk-8-jdk openjdk-8-jre gcc git wget llvm \
    clang ruby node.js golang redis-server couchdb python-pycassa \
    rabbitmq-server libsphinx-search-perl libpocketsphinx-dev ant

# Install maven.
wget http://mirror.olnevhost.net/pub/apache/maven/binaries/apache-maven-3.2.1-bin.tar.gz && tar xvf apache-maven-3.2.1-bin.tar.gz

# Set up environment.
export M2_HOME=`pwd`/apache-maven-3.2.1
export M2=$M2_HOME/bin
export PATH=$M2:$PATH
export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-ppc64el"

wget -O - https://debian.neo4j.org/neotechnology.gpg.key | sudo apt-key add -
echo 'deb http://debian.neo4j.org/repo stable/' > /tmp/neo4j.list
sudo mv /tmp/neo4j.list /etc/apt/sources.list.d
sudo apt-get update -y && sudo apt-get install -y neo4j

# Build the source and test it.
git clone https://github.com/logstash/logstash-logback-encoder.git
cd logstash-logback-encoder
mvn install -DskipTests=true -Dmaven.javadoc.skip=true -B -V && mvn test -B
