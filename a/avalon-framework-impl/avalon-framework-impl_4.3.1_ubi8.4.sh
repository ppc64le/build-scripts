# ----------------------------------------------------------------------------------------------------
#
# Package       : avalon-framework-impl
# Version       : 4.3.1
# Tested on     : UBI 8.4 (Docker)
# Script License: Apache License, Version 2 or later
# Maintainer    : Atharv Phadnis <Atharv.Phadnis@ibm.com>
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------------------------------

#!/bin/bash

set -ex

#Variables
REPO=https://repo1.maven.org/maven2/org/apache/avalon/framework/avalon-framework-impl
VERSION=4.3.1
PACKAGE_NAME=avalon-framework-impl

#Extract version from command line
echo "Usage: $0 [-v <VERSION>]"
echo "VERSION is an optional paramater whose default value is 4.3.1, not all versions are supported."
VERSION="${1:-$VERSION}"

#Dependencies
yum install -y java-1.8.0-openjdk-devel wget
cd /opt/
wget https://downloads.apache.org/maven/maven-3/3.8.3/binaries/apache-maven-3.8.3-bin.tar.gz
tar xzvf apache-maven-3.8.3-bin.tar.gz
export PATH=/opt/apache-maven-3.8.3/bin:$PATH

#Get the sources
mkdir ${PACKAGE_NAME}
cd ${PACKAGE_NAME}
wget ${REPO}/${VERSION}/${PACKAGE_NAME}-${VERSION}.pom
mv ${PACKAGE_NAME}-${VERSION}.pom pom.xml

mkdir -p src/java
mkdir -p src/test
cd src/java
wget ${REPO}/${VERSION}/${PACKAGE_NAME}-${VERSION}-sources.jar
jar xf ${PACKAGE_NAME}-${VERSION}-sources.jar
rm -f ${PACKAGE_NAME}-${VERSION}-sources.jar

#Build and test
cd /opt/${PACKAGE_NAME}
mvn test verify

#conclude
set +ex
find /opt/${PACKAGE_NAME} -name *.jar
echo "Complete!"