# ----------------------------------------------------------------------------
#
# Package	: wink
# Version	: 1.4.0
# Source repo	: https://github.com/apache/wink.git
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
sudo apt-get install -y openjdk-8-jdk openjdk-8-jre openjdk-8-jre-headless git wget maven
export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-ppc64el"
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8"

# Install maven.
wget http://archive.apache.org/dist/maven/maven-3/3.3.3/binaries/apache-maven-3.3.3-bin.tar.gz
tar -zxf apache-maven-3.3.3-bin.tar.gz
sudo cp -R apache-maven-3.3.3 /usr/local
sudo ln -s /usr/local/apache-maven-3.3.3/bin/mvn /usr/bin/mvn

# Clone and build source code.
git clone https://github.com/apache/wink.git
cd wink
mvn install
