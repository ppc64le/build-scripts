# ----------------------------------------------------------------------------
#
# Package       : Jena-arq
# Version       : jena-4.2.0
# Source repo   : https://github.com/apache/jena
# Tested on     : ubi: 8.3
# Script License: Apache License 2.0
# Maintainer's  : Hari Pithani <Hari.Pithani@ibm.com>
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
echo "       PACKAGE_VERSION is an optional paramater whose default value is jena-4.2.0"

#Variables.
PACKAGE_VERSION=jena-4.2.0
PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"
PACKAGE_NAME=jena/jena-arq
PACKAGE_URL=https://github.com/apache/jena.git

# Installation of required sotwares. 
yum update -y
yum install git wget java-11-openjdk-devel -y
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.12.0.7-0.el8_4.ppc64le
export PATH=$PATH:$JAVA_HOME/bin

#Maven installation steps.
wget http://mirrors.estointernet.in/apache/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
tar -C /usr/local/ -xzf apache-maven-3.6.3-bin.tar.gz
mv /usr/local/apache-maven-3.6.3 /usr/local/maven
ls /usr/local
rm -rf apache-maven-3.6.3-bin.tar.gz 
export M2_HOME=/usr/local/maven
# update the path env. variable 
export PATH=$PATH:$M2_HOME/bin

# Cloning the repository from remote to local. 
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "${PACKAGE_VERSION} found to checkout"
else
  echo  "${PACKAGE_VERSION} not found"
  exit
fi

# Build and test.
mvn test
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done Test ......"
else
  echo  "Failed Test ......"
fi

mvn install -DskipTests
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done build ..."
else
  echo  "Failed build......"
  exit
fi


