# ----------------------------------------------------------------------------------------------------
#
# Package       : lz4-java
# Version       : 1.7.1
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
REPO=https://github.com/lz4/lz4-java.git
VERSION=1.7.1
PACKAGE_NAME=lz4-java
ARCH=$(arch)

#Extract version from command line
echo "Usage: $0 [-v <VERSION>]"
echo "VERSION is an optional paramater whose default value is 1.7.1, not all versions are supported."
VERSION="${1:-$VERSION}"

#Dependencies
yum install -y git wget unzip gcc java-1.8.0-openjdk-devel
cd /opt/
wget https://dlcdn.apache.org//ant/binaries/apache-ant-1.10.12-bin.zip
unzip apache-ant-1.10.12-bin.zip
export ANT_HOME=/opt/apache-ant-1.10.12
export PATH=/opt/apache-ant-1.10.12/bin:$PATH
dnf -y install https://dl02.fedoraproject.org/pub/epel/8/Everything/ppc64le/Packages/x/xxhash-libs-0.8.0-3.el8.ppc64le.rpm
dnf -y install https://dl02.fedoraproject.org/pub/epel/8/Everything/ppc64le/Packages/x/xxhash-devel-0.8.0-3.el8.ppc64le.rpm
dnf -y install lz4

#Get the sources
git clone ${REPO}
cd ${PACKAGE_NAME}
git checkout $VERSION
git submodule init
git submodule update
mkdir -p src/lz4/lib

#Build and test
ant ivy-bootstrap
ant test

#conclude
set +ex
find /opt/${PACKAGE_NAME} -name *.jar
echo "Build and test Complete."
