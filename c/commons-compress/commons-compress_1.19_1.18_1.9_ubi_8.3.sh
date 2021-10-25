# ----------------------------------------------------------------------------------------------------
#
# Package       : jquery
# Version       : 1.19, 1.18, 1.9
# Tested on     : UBI 8.3 (Docker)
# Script License: Apache License, Version 2 or later
# Maintainer    : Sumit Dubey <Sumit.Dubey2@ibm.com>
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
REPO=https://github.com/apache/commons-compress.git
PACKAGE_VERSION=1.19

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is 1.19, not all versions are supported."
PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#Dependencies
yum install -y java-1.8.0-openjdk-devel git wget
cd /opt/
wget https://dlcdn.apache.org/maven/maven-3/3.8.3/binaries/apache-maven-3.8.3-bin.tar.gz
tar xzvf apache-maven-3.8.3-bin.tar.gz
export PATH=/opt/apache-maven-3.8.3/bin:$PATH

#Clone
git clone $REPO
cd commons-compress/
git checkout rel/$PACKAGE_VERSION

#Build and test
mvn verify -Dorg.ops4j.pax.url.mvn.repositories="https://repo1.maven.org/maven2@id=central"
