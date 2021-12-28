# ----------------------------------------------------------------------------------------------------
#
# Package       : commons-io
# Version       : 2.4, 2.5
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
REPO=https://github.com/apache/commons-io.git
PACKAGE_VERSION=2.4

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is 2.4, not all versions are supported."
PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#Dependencies
yum install -y java-1.8.0-openjdk-devel git wget
cd /opt/
wget https://downloads.apache.org/maven/maven-3/3.8.3/binaries/apache-maven-3.8.3-bin.tar.gz
tar xzvf apache-maven-3.8.3-bin.tar.gz
export PATH=/opt/apache-maven-3.8.3/bin:$PATH

#Clone
git clone $REPO
cd commons-io/
if [ "$PACKAGE_VERSION" = "master" ]
then
	git checkout master
elif [ "$PACKAGE_VERSION" = "2.4" ] || [ "$PACKAGE_VERSION" = "2.5" ]
then
	git checkout $PACKAGE_VERSION
else
	git checkout rel/commons-io-$PACKAGE_VERSION
fi

#Build and test
mvn verify -ff
