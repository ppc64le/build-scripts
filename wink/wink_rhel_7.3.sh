# ----------------------------------------------------------------------------
#
# Package	: wink
# Version	: 1.4.0
# Source repo	: https://github.com/apache/wink.git
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
sudo yum -y update
sudo yum install -y git wget tar \
    java-1.8.0-openjdk java-1.8.0-openjdk-devel java-1.8.0-openjdk-headless

# Install maven.
wget http://archive.apache.org/dist/maven/maven-3/3.3.3/binaries/apache-maven-3.3.3-bin.tar.gz
tar -xvzf apache-maven-3.3.3-bin.tar.gz
sudo cp -R apache-maven-3.3.3 /usr/local
sudo ln -s /usr/local/apache-maven-3.3.3/bin/mvn /usr/bin/mvn

export JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk"
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8"
export MAVEN_HOME="/tmp/apache-maven-3.3.3"

# Clone and build source code.
git clone https://github.com/apache/wink.git
cd wink
mvn install
