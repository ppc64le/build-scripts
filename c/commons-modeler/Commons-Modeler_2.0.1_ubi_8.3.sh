# ----------------------------------------------------------------------------------------------------
#
# Package       : Commons-Modeler
# Version       : 2.0.1
# Source repo   : https://repo1.maven.org/maven2/commons-modeler/commons-modeler
# Tested on     : UBI 8.3 (Docker)
# Script License: Apache License, Version 2 or later
# Maintainer    : Balavva Mirji <Balavva.Mirji@ibm.com>
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
REPO=https://repo1.maven.org/maven2/commons-modeler/commons-modeler
VERSION=2.0.1
PACKAGE_NAME=commons-modeler

#Extract version from command line
echo "Usage: $0 [-v <VERSION>]"
echo "VERSION is an optional paramater whose default value is 20100527, not all versions are supported."
VERSION="${1:-$VERSION}"

#Dependencies
yum install -y java-1.8.0-openjdk-devel git wget
cd /opt/
wget https://downloads.apache.org/maven/maven-3/3.8.3/binaries/apache-maven-3.8.3-bin.tar.gz
tar xzvf apache-maven-3.8.3-bin.tar.gz
export PATH=/opt/apache-maven-3.8.3/bin:$PATH

#Get the sources
mkdir ${PACKAGE_NAME}
cd ${PACKAGE_NAME}
wget ${REPO}/${VERSION}/${PACKAGE_NAME}-${VERSION}.pom
mv ${PACKAGE_NAME}-${VERSION}.pom pom.xml
head -172 pom.xml > temp.xml
tail -1 pom.xml >> temp.xml
cat temp.xml > pom.xml
rm temp.xml
mkdir -p src/main/java
cd src/main/java
wget ${REPO}/${VERSION}/${PACKAGE_NAME}-${VERSION}-sources.jar
jar xf ${PACKAGE_NAME}-${VERSION}-sources.jar
rm -f ${PACKAGE_NAME}-${VERSION}-sources.jar

#Build and test
cd /opt/${PACKAGE_NAME}
mvn clean install -DskipTests
mvn test

#conclude
set +ex
find /opt/${PACKAGE_NAME} -name *.jar
echo "Complete!"