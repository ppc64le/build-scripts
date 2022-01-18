# ---------------------------------------------------------------------------
#
# Package       : commons-math3
# Version       : 3.6.1
# Source repo   : https://github.com/apache/commons-math.git
# Tested on     : UBI: 8.4
# Script License: Apache License 2.0
# Maintainer's  : Sapana Khemkar <Sapana.Khemkar@ibm.com>
# Language	: Java
#
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
PACKAGE_URL=https://github.com/apache/commons-math.git
PACKAGE_VERSION=MATH_3_6_1
PACKAGE_NAME=commons-math


# install tools and dependent packages
yum update -y
yum install -y git wget tar

# install java
yum -y install java-1.8.0-openjdk-devel

#install maven
cd /opt/
rm -rf apache-maven*
rm -rf maven
wget https://www-eu.apache.org/dist/maven/maven-3/3.8.4/binaries/apache-maven-3.8.4-bin.tar.gz
tar xzf apache-maven-3.8.4-bin.tar.gz
ln -s apache-maven-3.8.4 maven
export MVN_HOME=/opt/maven
export PATH=${MVN_HOME}/bin:${PATH}
mvn -version

# Cloning the repository from remote to local
cd /home
rm -rf $PACKAGE_NAME
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Build and test package
mvn package
mvn test

exit 0
