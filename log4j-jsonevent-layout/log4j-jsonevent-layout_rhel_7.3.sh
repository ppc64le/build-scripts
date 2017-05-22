# ----------------------------------------------------------------------------
#
# Package	: log4j-jsonevent-layout
# Version	: 1.7
# Source repo	: https://github.com/logstash/log4j-jsonevent-layout
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

#Install dependencies needed for building and testing
sudo yum update -y
sudo yum install -y git wget java-1.7.0-openjdk-devel maven which
export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

wget https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/3.3.3/apache-maven-3.3.3-bin.tar.gz
tar -zxf apache-maven-3.3.3-bin.tar.gz
sudo cp -R apache-maven-3.3.3 /usr/local
sudo ln -s /usr/local/apache-maven-3.3.3/bin/mvn /usr/bin/mvn

# Build the source and install.
git clone https://github.com/logstash/log4j-jsonevent-layout log4j-jsonevent-layout
cd log4j-jsonevent-layout
sudo mvn install
