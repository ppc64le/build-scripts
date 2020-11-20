# ----------------------------------------------------------------------------
#
# Package	: tinkerpop
# Version	: 3.4.0-rc1, 3.3.4
# Source repo	: https://github.com/apache/tinkerpop
# Tested on	: ubuntu_18.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

#Install dependencies
sudo apt-get update
sudo apt-get install openjdk-8-jdk maven git  

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH

git clone https://github.com/apache/tinkerpop
cd tinkerpop
mvn clean install
