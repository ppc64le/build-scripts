# ----------------------------------------------------------------------------
#
# Package       : Classgraph
# Version       : 4.8.110
# Source repo   : https://github.com/classgraph/classgraph
# Tested on     : UBI 8.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Vaibhav Nazare <Vaibhav.Nazare@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
# Tested versions: 4.8.110, 4.8.78
#!/bin/bash

#Variables
REPO=https://github.com/classgraph/classgraph.git
PACKAGE_VERSION=classgraph-4.8.110 

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is classgraph-4.8.110"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#Install required dependencies
yum update -y
yum install -y git java-11-openjdk-devel wget
JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.13.0.8-1.el8_4.ppc64le
export JAVA_HOME
wget https://downloads.apache.org/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
tar -zxvf apache-maven-3.6.3-bin.tar.gz
mkdir /opt/maven
mv apache-maven-3.6.3 /opt/maven
sed -i "$ a export M2_HOME=/opt/maven/apache-maven-3.6.3" /etc/profile
sed -i "$ a export PATH=\${M2_HOME}/bin:\${PATH}" /etc/profile
source /etc/profile

#Cloning Repo
git clone $REPO
cd classgraph/
git checkout $PACKAGE_VERSION

#Build and test package
mvn package -DskipTests
mvn -Dmaven.test.failure.ignore=true test
