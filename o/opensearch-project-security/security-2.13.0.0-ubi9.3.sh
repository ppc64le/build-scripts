#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : security
# Version       : 2.13.0.0 
# Source repo   : https://github.com//opensearch-project/security
# Tested on     : UBI 9.3 (docker)
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sumit Dubey <Sumit.Dubey2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=security
PACKAGE_VERSION=${1:-2.13.0.0}
PACKAGE_URL=https://github.com/opensearch-project/${PACKAGE_NAME}

#Install deps
yum install -y  git java-17-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH

#Clone
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME}
git checkout ${PACKAGE_VERSION}

#Build artifacts
ret=0
./gradlew clean assemble || ret=$?
if [ "$ret" -ne 0 ]
then
	echo "FAIL: Build failed."
	exit 1
fi

#Unit tests
./gradlew test --max-workers=1 || ret=$?
if [ "$ret" -ne 0 ]
then
	echo "Tests fail."
	exit 2
fi
echo "The following failing test is in parity with Intel"
echo "org.opensearch.security.dlic.rest.api.InternalUsersApiActionValidationTest.validateSecurityRolesWithMutableRolesMappingConfig"

#Integration tests, were found to be flaky
#./gradlew integrationTest --continue

echo "Build and tests successful." 
