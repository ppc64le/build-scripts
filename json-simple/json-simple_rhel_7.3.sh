# ----------------------------------------------------------------------------
#
# Package	: json-simple
# Version	: 1.1.1
# Source repo	: https://github.com/fangyidong/json-simple
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
sudo yum install -y which git wget java-1.7.0-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk
export PATH=$PATH:$JAVA_HOME/bin

wget http://archive.apache.org/dist/maven/maven-3/3.3.3/binaries/apache-maven-3.3.3-bin.tar.gz
tar -zxf apache-maven-3.3.3-bin.tar.gz
sudo cp -R apache-maven-3.3.3 /usr/local
sudo ln -s /usr/local/apache-maven-3.3.3/bin/mvn /usr/bin/mvn

# Clone and build code.
git clone https://github.com/fangyidong/json-simple
cd json-simple
sudo mvn install
