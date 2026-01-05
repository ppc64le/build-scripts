#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : httpcomponents-client
# Version       : v5.4
# Source repo   : https://github.com/apache/httpcomponents-client
# Tested on     : UBI 9.5 (ppc64le)
# Language      : Java
# Ci-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : Sanket Patil <Sanket.Patil11@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME="httpcomponents-client"
PACKAGE_VERSION="${1:-rel/v5.4}"
PACKAGE_URL="https://github.com/apache/httpcomponents-client"
WORK_DIR=$(pwd)

yum install -y java-17-openjdk java-17-openjdk-devel java-17-openjdk-headless git maven
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH

cd "$WORK_DIR"
git clone "$PACKAGE_URL"
cd "$PACKAGE_NAME"
git checkout "$PACKAGE_VERSION"

# Build the package
ret=0
mvn install -DskipTests || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "ERROR: $PACKAGE_NAME - Build failed."
    exit 1
else
    echo "INFO: $PACKAGE_NAME - Build successful."
fi

# Run tests
mvn test || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "ERROR: $PACKAGE_NAME - Test phase failed."
    exit 2
else
    echo "INFO: $PACKAGE_NAME - All tests passed."
fi

echo "SUCCESS: $PACKAGE_NAME version $PACKAGE_VERSION built and tested successfully."
exit 0
