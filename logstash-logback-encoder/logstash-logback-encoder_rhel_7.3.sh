# ----------------------------------------------------------------------------
#
# Package	: logstash-logback-encoder
# Version	: 4.9
# Source repo	: https://github.com/logstash/logstash-logback-encoder
# Tested on	: rhel_7.3
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
sudo yum update -y
sudo yum install -y git gcc wget make python maven ant rpm which \
    java-1.8.0-openjdk-devel.ppc64le rpm-build
sudo yum groupinstall "Development Tools" -y

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

# Install maven.
wget http://mirror.olnevhost.net/pub/apache/maven/binaries/apache-maven-3.2.1-bin.tar.gz
tar xvf apache-maven-3.2.1-bin.tar.gz
export M2_HOME=`pwd`/apache-maven-3.2.1
export M2=$M2_HOME/bin
export PATH=$M2:$PATH

# Build the source and test it.
git clone https://github.com/logstash/logstash-logback-encoder.git
cd logstash-logback-encoder
mvn install -DskipTests=true -Dmaven.javadoc.skip=true -B -V && mvn test -B
