# ----------------------------------------------------------------------------
#
# Package       : jgrapht
# Version       : 1.1.0
# Source repo   : https://github.com/jgrapht/jgrapht
# Tested on     : rhel_7.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

sudo yum update -y
sudo yum install -y git java-1.8.0-openjdk-devel wget

#Install maven
wget http://www-us.apache.org/dist/maven/maven-3/3.5.2/binaries/apache-maven-3.5.2-bin.tar.gz
tar -zxvf apache-maven-3.5.2-bin.tar.gz

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH:`pwd`/apache-maven-3.5.2/bin

git clone https://github.com/jgrapht/jgrapht
cd jgrapht
mvn install
