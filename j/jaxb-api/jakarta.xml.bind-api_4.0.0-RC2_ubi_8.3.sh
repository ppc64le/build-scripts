# ----------------------------------------------------------------------------
#
# Package       : jakarta.xml.bind-api
# Version       : 4.0.0-RC2
# Source repo   : https://github.com/eclipse-ee4j/jaxb-api.git
# Tested on     : UBI 8.3
# Script License: Apache-2.0 License
# Maintainer    : Balavva Mirji <Balavva.Mirji@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

#Variables
REPO=https://github.com/eclipse-ee4j/jaxb-api

# Default tag for jakarta.xml.bind-api
if [ -z "$1" ]; then
  export VERSION="4.0.0-RC2"
else
  export VERSION="$1"
fi

# install tools and dependent packages
yum update -y
yum install -y git wget java-11-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.13.0.8-1.el8_4.ppc64le

# install maven
wget https://dlcdn.apache.org/maven/maven-3/3.8.3/binaries/apache-maven-3.8.3-bin.tar.gz
tar -C /usr/local/ -xzvf apache-maven-3.8.3-bin.tar.gz
rm -rf tar xzvf apache-maven-3.8.3-bin.tar.gz
mv /usr/local/apache-maven-3.8.3 /usr/local/maven
export M2_HOME=/usr/local/maven
export PATH=$PATH:$M2_HOME/bin

# Cloning Repo
git clone $REPO
cd jaxb-api

git checkout $VERSION

# Build and test package
mvn -B -V -U -C -Poss-release clean verify org.glassfish.copyright:glassfish-copyright-maven-plugin:check -Dgpg.skip=true
mvn clean install 
#No tests cases to run