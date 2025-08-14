#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : rest-assured
# Version       : v5.5.0
# Source repo   : https://github.com/rest-assured/rest-assured
# Tested on     : UBI 9.5 (ppc64le)
# Language      : Java
# Travis-Check  : true
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

PACKAGE_NAME="rest-assured"
PACKAGE_VERSION="${1:-5.5.0}"
PACKAGE_URL="https://github.com/rest-assured/rest-assured"
WORK_DIR=$(pwd)

yum update -y
yum -y remove java-1.8.0-openjdk* java-11-openjdk* java-17-openjdk* || true
yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel java-1.8.0-openjdk-headless
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

yum install -y git maven

# Clone Repository
cd "$WORK_DIR"
git clone "$PACKAGE_URL"
cd "$PACKAGE_NAME"
git checkout "$PACKAGE_NAME-$PACKAGE_VERSION"

# Build the package
ret=0
mvn clean install -DskipTests -B || ret=$?
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
