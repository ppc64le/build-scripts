#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : aether-api, aether-spi
# Version       : aether-1.13.1
# Source repo   : https://github.com/sonatype/sonatype-aether
# Tested on     : UBI: 8.4
# Script License: Apache License 2.0
# Maintainer    : Sapana Khemkar <Sapana.Khemkar@ibm.com>/ Balavva Mirji <Balavva.Mirji@ibm.com>
# Language	    : Java
# Travis-Check  : True
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=sonatype-aether
PACKAGE_URL=https://github.com/sonatype/sonatype-aether.git
PACKAGE_VERSION=${1:-aether-1.13.1}


# install tools and dependent packages
yum install -y git wget

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

cd aether-api
mvn clean package

cd ..
cd aether-spi
mvn clean package

exit 0
