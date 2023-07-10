#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : nifi
# Version       : 1.22.0
# Source repo   : https://github.com/apache/nifi
# Tested on     : UBI: 8.5
# Travis-Check  : True
# Language      : Java
# Script License: Apache License Version 2.0
# Maintainer    : Vishaka Desai <Vishaka.Desai@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_VERSION=${1:-rel/nifi-1.22.0}

# Install dependecies
yum install -y wget git 

# Install java
yum install -y java-17-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-17)(?=.*ppc64le)')
export PATH=$JAVA_HOME/bin:$PATH

# Install maven
wget https://archive.apache.org/dist/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz
tar -xvzf apache-maven-3.8.6-bin.tar.gz
cp -R apache-maven-3.8.6 /usr/local
ln -s /usr/local/apache-maven-3.8.6/bin/mvn /usr/bin/mvn

# Build the package
git clone https://github.com/apache/nifi
cd nifi
git checkout $PACKAGE_VERSION

sed -i '/<artifactId>snappy-java<\/artifactId>/!b;n;c\\t\t<version>1.1.8</version>' pom.xml
find="<additionalJOption>\-J\-Xmx512m<\/additionalJOption>"
replace="<additionalJOptions>\
<additionalJOption>\-J\-Xmx3g</additionalJOption>\
<additionalJOption>\-J\-XX:+UseG1GC<\/additionalJOption>\
<additionalJOption>\-J\-XX:ReservedCodeCacheSize=1g<\/additionalJOption>\
<\/additionalJOptions>"
sed -i "s#$find#$replace#g" pom.xml

mvn install -Dmaven.test.skip=true

# Test failures noted to be in parity with Intel, thus disabled
# mvn test