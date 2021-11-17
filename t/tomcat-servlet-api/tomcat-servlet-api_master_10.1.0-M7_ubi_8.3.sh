# ----------------------------------------------------------------------------------------------------
#
# Package       : tomcat-servlet-api
# Version       : 10.1.0-M7
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
REPO=https://github.com/apache/tomcat.git
VERSION=10.1.0-M7
PACKAGE_NAME=tomcat

#Extract version from command line
echo "Usage: $0 [-v <VERSION>]"
echo "VERSION is an optional paramater whose default value is 10.1.0-M7, not all versions are supported."
VERSION="${1:-$VERSION}"

#Dependencies
yum install -y java-11-openjdk-devel git wget unzip
cd /opt/
wget https://dlcdn.apache.org//ant/binaries/apache-ant-1.10.12-bin.zip
unzip apache-ant-1.10.12-bin.zip
export ANT_HOME=/opt/apache-ant-1.10.12
export PATH=/opt/apache-ant-1.10.12/bin:$PATH

#Get the sources
git clone ${REPO}
cd ${PACKAGE_NAME}
if [[ "$VERSION" = "master" ]]
then
	git checkout main
else
	git checkout $VERSION
fi

#Build and test
ant test

#conclude
set +ex
find /opt/${PACKAGE_NAME} -name *servlet-api.jar
echo "Build and test Complete."
