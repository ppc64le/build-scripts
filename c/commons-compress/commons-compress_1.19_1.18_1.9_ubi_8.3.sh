#!/bin/bash -e
# ----------------------------------------------------------------------------------------------------
#
# Package         : commons-compress
# Version         : 1.19, 1.18, 1.9, 1.2
# Source Repo     : https://github.com/apache/commons-compress
# Tested on       : UBI 8.3 (Docker)
# Language        : Java
# Travis-Check    : True
# Script License  : Apache License, Version 2 or later
# Maintainer      : Sumit Dubey <Sumit.Dubey2@ibm.com>
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------------------------------

#Variables
REPO=https://github.com/apache/commons-compress.git
PACKAGE_VERSION=1.19
PACKAGE_NAME=commons-compress

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is 1.19, not all versions are supported."
PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#Dependencies
yum install -y java-1.8.0-openjdk-devel git wget
wget https://dlcdn.apache.org/maven/maven-3/3.8.5/binaries/apache-maven-3.8.5-bin.tar.gz
tar -zxvf apache-maven-3.8.5-bin.tar.gz
mv apache-maven-3.8.5 /opt/maven
export M2_HOME=/opt/maven
export PATH=${M2_HOME}/bin:${PATH}

#Clone
git clone $REPO
cd $PACKAGE_NAME
git checkout rel/$PACKAGE_VERSION

#Build and test
mvn verify -Dorg.ops4j.pax.url.mvn.repositories="https://repo1.maven.org/maven2@id=central"
