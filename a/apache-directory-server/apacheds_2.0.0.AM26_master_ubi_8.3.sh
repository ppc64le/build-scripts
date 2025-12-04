# ----------------------------------------------------------------------------------------------------
#
# Package       : directory-server
# Version       : 2.0.0.AM26, master
# Source repo	: https://github.com/apache/directory-server
# Tested on     : UBI 8.3 (Docker)
# Language      : java
# Ci-Check  : false
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
REPO=https://github.com/apache/directory-server.git
VERSION=2.0.0.AM26
PACKAGE_NAME=directory-server

#Extract version from command line
echo "Usage: $0 [-v <VERSION>]"
echo "VERSION is an optional paramater whose default value is 20100527, not all versions are supported."
VERSION="${1:-$VERSION}"

#Dependencies
yum install -y git wget
cd /opt/
wget https://downloads.apache.org/maven/maven-3/3.8.3/binaries/apache-maven-3.8.3-bin.tar.gz
tar xzvf apache-maven-3.8.3-bin.tar.gz
export PATH=/opt/apache-maven-3.8.3/bin:$PATH
cat <<'EOF' > /etc/yum.repos.d/adoptopenjdk.repo
[AdoptOpenJDK]
name=AdoptOpenJDK
baseurl=http://adoptopenjdk.jfrog.io/adoptopenjdk/rpm/centos/$releasever/$basearch
enabled=1
gpgcheck=1
gpgkey=https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public
EOF
yum install -y adoptopenjdk-11-hotspot

#Get the sources
git clone ${REPO}
cd ${PACKAGE_NAME}
git checkout ${VERSION}

#patch
sed -i "s#checkstyle-configuration.version>2.0.1-SNAPSHOT#checkstyle-configuration.version>2.0.1#g"  pom.xml

#Build and test, the 2 test errors for 2.0.0.AM26 are in parity with x86
mvn clean package -f "pom.xml" -B -V -e -Dfindbugs.skip -Dcheckstyle.skip -Dpmd.skip=true -Denforcer.skip -Dmaven.javadoc.skip -Dlicense.skip=true -Drat.skip=true -fn

#conclude
set +ex
echo "Complete!"
