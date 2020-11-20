# ----------------------------------------------------------------------------
#
# Package       : codeready-workspaces
# Version       : 2.0.0.GA
# Source repo   : https://github.com/redhat-developer/codeready-workspaces
# Tested on     : ppc64le_rhel7.6
# Script License: Eclipse Public License 2.0
# Maintainer's  : Rashmi Sakhalkar <srashmi@us.ibm.com>
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

yum update -y && yum install -y make hostname curl-devel openssl-devel unzip wget java-1.8.0-openjdk java-1.8.0-openjdk-devel expat-devel gettext-devel zlib-devel perl-ExtUtils-MakeMaker
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk

BUILD_HOME=`pwd`
BUILD_VERSION=2.0.0.GA

#Install maven
cd /
wget http://www-eu.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz

tar xzf apache-maven-3.6.3-bin.tar.gz

ln -s apache-maven-3.6.3 /maven

#Set mvn variables
export M2_HOME=/maven
export PATH=${M2_HOME}/bin:${PATH}
mvn --version

#Build codeready-workspaces
cd $BUILD_HOME
git clone https://github.com/redhat-developer/codeready-workspaces

cd codeready-workspaces/
git checkout $BUILD_VERSION

mvn clean install