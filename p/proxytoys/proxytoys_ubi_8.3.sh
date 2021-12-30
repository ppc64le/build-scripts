# ----------------------------------------------------------------------------
#
# Package       : Proxytoys
# Version       : 1.0
# Source repo   : https://github.com/proxytoys/proxytoys
# Tested on     : UBI: 8.3
# Script License: Apache License 2.0
# Maintainer's  : Balavva Mirji <Balavva.Mirji@ibm.com>
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

# Variables
REPO=https://github.com/proxytoys/proxytoys

# Default tag for Proxytoys
if [ -z "$1" ]; then
  export VERSION="1.0"
else
  export VERSION="$1"
fi

# Install tools and dependent packages
yum update -y
yum install -y git wget

# install java
yum install -y java-1.8.0-openjdk-devel

# install maven
MAVEN_VERSION=3.6.3
wget http://mirrors.estointernet.in/apache/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz
ls /usr/local
tar -C /usr/local/ -xzf apache-maven-$MAVEN_VERSION-bin.tar.gz
mv /usr/local/apache-maven-$MAVEN_VERSION /usr/local/maven
ls /usr/local
rm apache-maven-$MAVEN_VERSION-bin.tar.gz
export M2_HOME=/usr/local/maven
# update the path env. variable 
export PATH=$PATH:$M2_HOME/bin

#Cloning Repo
git clone $REPO
cd /proxytoys

git checkout ${VERSION}
cd /proxytoys/proxytoys

mvn validate
mvn install -B -V