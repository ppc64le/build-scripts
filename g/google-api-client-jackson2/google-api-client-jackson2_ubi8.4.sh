# ----------------------------------------------------------------------------
#
# Package	: google-api-client-jackson2
# Version	: 1.27.0
# Source repo	: https://github.com/googleapis/google-api-java-client
# Tested on	: ubi 8.4
# Script License: Apache License Version 2.0
# Maintainer	: Sapana Khemkar <sapana.khemkar@ibm.com>
# Languge	: Java
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash
set -e

# Variables
PACKAGE_NAME=google-api-client-jackson2
PACKAGE_URL=https://github.com/googleapis/google-api-java-client.git
PACKAGE_VERSION=1.27.0
PACKAGE_DIR=google-api-java-client

# install tools and dependent packages
yum install -y git wget tar

# install java
yum -y install java-1.8.0-openjdk-devel

#install maven
cd /opt/
wget https://www-eu.apache.org/dist/maven/maven-3/3.8.4/binaries/apache-maven-3.8.4-bin.tar.gz
tar xzf apache-maven-3.8.4-bin.tar.gz
ln -s apache-maven-3.8.4 maven
export MVN_HOME=/opt/maven
export PATH=${MVN_HOME}/bin:${PATH}
mvn -version

# Cloning the repository from remote to local
cd /home
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout v$PACKAGE_VERSION
cd $PACKAGE_NAME
mvn install

exit 0
