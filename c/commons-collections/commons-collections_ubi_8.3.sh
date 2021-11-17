# ----------------------------------------------------------------------------
#
# Package       : commons-collections
# Version       : 4.1
# Source repo   : https://github.com/apache/commons-collections
# Tested on     : UBI: 8.3
# Script License: Apache License 2.0
# Maintainer's  : Jotirling Swami <Jotirling.Swami1@ibm.com>
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

echo "Usage: $0 [<PACKAGE_VERSION>]"
echo "       PACKAGE_VERSION is an optional paramater whose default value is collections-4.1 and also support for version collections-4.0"

# Variables
REPO=https://github.com/apache/commons-collections.git
PACKAGE_VERSION=collections-4.1
PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"
DIR=commons-collections

echo "Building for version - $PACKAGE_VERSION"

# install tools and dependent packages
yum update -y
yum install -y git wget

# install java
yum -y install java-1.8.0-openjdk-devel

#install maven
cd /opt/
wget https://www-eu.apache.org/dist/maven/maven-3/3.8.3/binaries/apache-maven-3.8.3-bin.tar.gz
tar xzf apache-maven-3.8.3-bin.tar.gz
ln -s apache-maven-3.8.3 maven
export MVN_HOME=/opt/maven
export PATH=${MVN_HOME}/bin:${PATH}
mvn -version

# Cloning the repository from remote to local
cd /home
git clone $REPO
cd $DIR
git checkout $PACKAGE_VERSION

# Build and test package
mvn package
mvn test
