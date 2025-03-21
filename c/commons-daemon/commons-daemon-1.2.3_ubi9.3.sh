#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: commons-daemon
# Version	: rel/commons-daemon-1.2.3
# Source repo	: https://github.com/apache/commons-daemon.git
# Tested on	: UBI 9.3
# Language      : Java
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer	: Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=commons-daemon
PACKAGE_VERSION=${1:-rel/commons-daemon-1.2.3}
PACKAGE_URL=https://github.com/apache/$PACKAGE_NAME.git

# Install tools and dependent packages
yum update -y
yum install -y git wget tar java-1.8.0-openjdk-devel

#install maven
cd /opt/
rm -rf apache-maven*
rm -rf maven
wget https://dlcdn.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz
tar xzf apache-maven-3.9.9-bin.tar.gz
ln -s apache-maven-3.9.9 maven
export MVN_HOME=/opt/maven
export PATH=${MVN_HOME}/bin:${PATH}
mvn -version

# Cloning the repository from remote to local
cd /home
rm -rf $PACKAGE_NAME
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Build the package
ret=0
mvn -T $(nproc) package || ret=$?
if [ "$ret" -ne 0 ]
then
	exit 1
fi
# Test
mvn test || ret=$?
if [ "$ret" -ne 0 ]
then
	exit 2
fi
echo "SUCCESS: Build and test success!"
exit
