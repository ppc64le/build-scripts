# ----------------------------------------------------------------------------
#
# Package	: commons-codec
# Version	: commons-codec-1.13, commons-codec-1.12, 1.9
# Source repo	: https://github.com/apache/commons-codec
# Tested on	: ubi 8.4
# Script License: Apache License Version 2.0
# Maintainer	: Sapana Khemkar <sapana.khemkar@ibm.com>
# Language	: Java
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
PACKAGE_NAME=commons-codec
PACKAGE_URL=https://github.com/apache/commons-codec.git
PACKAGE_VERSION=commons-codec-1.13

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is r1rv68, not all versions are supported."

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"


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
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

mvn clean test

exit 0
