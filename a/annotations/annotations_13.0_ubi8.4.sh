# ----------------------------------------------------------------------------------------------------
#
# Package       : annotations
# Version       : 13.0
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
REPO=https://repo1.maven.org/maven2/org/jetbrains/annotations
VERSION=13.0
PACKAGE_NAME=annotations

#Extract version from command line
echo "Usage: $0 [-v <VERSION>]"
echo "VERSION is an optional paramater whose default value is 13.0, not all versions are supported."
VERSION="${1:-$VERSION}"

#Dependencies
yum install -y java-1.8.0-openjdk-devel pinentry wget
cd /opt/
wget https://downloads.apache.org/maven/maven-3/3.8.3/binaries/apache-maven-3.8.3-bin.tar.gz
tar xzvf apache-maven-3.8.3-bin.tar.gz
export PATH=/opt/apache-maven-3.8.3/bin:$PATH

#Get pom
mkdir ${PACKAGE_NAME}
cd ${PACKAGE_NAME}
wget ${REPO}/${VERSION}/${PACKAGE_NAME}-${VERSION}.pom
mv ${PACKAGE_NAME}-${VERSION}.pom pom.xml

# Add configuration changes to, and remove unnecessary files fetches from pom.xml
sed -i '/<version>2.9.1<\/version>/a </configuration>' pom.xml
sed -i '/<version>2.9.1<\/version>/a <additionalparam>-Xdoclint:accessibility,reference,syntax</additionalparam>' pom.xml
sed -i '/<version>2.9.1<\/version>/a <configuration>' pom.xml
sed -i '/generate-sources/{n;N;N;N;N;N;N;N;N;d}' pom.xml
sed -i '/66770193/d' pom.xml
sed -i 's/${basedir}/\/root/' pom.xml

# Get source jar
mkdir -p src/main/java
cd src/main/java
wget ${REPO}/${VERSION}/${PACKAGE_NAME}-${VERSION}-sources.jar
jar xf ${PACKAGE_NAME}-${VERSION}-sources.jar
rm -f ${PACKAGE_NAME}-${VERSION}-sources.jar

# Generate gpg key for maven-gpg-plugin
cat >gpggen <<EOF
%echo Generating a default key
%no-protection
Key-Type: default
Subkey-Type: default
Name-Real: Joe Tester
Name-Email: joe@foo.bar
Expire-Date: 0
%commit
%echo done
EOF
gpg --batch --generate-key gpggen

#Build and test
cd /opt/${PACKAGE_NAME}
mvn test verify -Dgpg.passphrase=''

#conclude
set +ex
find /opt/${PACKAGE_NAME} -name *.jar
echo "Complete!"