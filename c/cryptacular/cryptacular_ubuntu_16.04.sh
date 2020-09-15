# ----------------------------------------------------------------------------
#
# Package	: cryptacular
# Version	: 1.2.1
# Source repo	: https://github.com/vt-middleware/cryptacular
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

# Update source
sudo apt-get update -y

# Install dependencies
sudo apt-get install -y ant git openjdk-8-jdk openjdk-8-dbg
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export PATH=$PATH:$JAVA_HOME/bin

WDIR=`pwd`

# Install maven
git clone https://git-wip-us.apache.org/repos/asf/maven.git
cd maven
git checkout maven-3.3.9
export M2_HOME=$WDIR/maven_code/maven-3.3.9-SNAPSHOT
export PATH=$M2_HOME/bin:$PATH
ant

# Build and Install
cd $WDIR
git clone https://github.com/vt-middleware/cryptacular
cd cryptacular
mvn test
