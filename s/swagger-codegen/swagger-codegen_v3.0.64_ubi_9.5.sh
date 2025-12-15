#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : swagger-codegen
# Version       : 3.0.64
# Source repo   : https://github.com/swagger-api/swagger-codegen
# Tested on     : UBI 9.5
# Language      : Java
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sanket Patil <Sanket.Patil11@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
PACKAGE_NAME="swagger-codegen"
PACKAGE_VERSION="${1:-v3.0.64}"
PACKAGE_URL="https://github.com/swagger-api/swagger-codegen"

# Install Dependencies
yum install -y git wget gcc gcc-c++ java-11-openjdk java-11-openjdk-devel java-11-openjdk-headless maven

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$JAVA_HOME/bin:$PATH

# Clone Repository
git clone "$PACKAGE_URL"
cd "$PACKAGE_NAME"
git checkout "$PACKAGE_VERSION"

# Build Package
ret=0
mvn clean install -DskipTests || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "---- ${PACKAGE_NAME}: Build Failed ----"
    exit 1
else
    echo "---- ${PACKAGE_NAME}: Build Success ----"
fi

# Test
mvn test || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "---- ${PACKAGE_NAME}: Tests Failed ----"
    exit 2
else
    echo "---- ${PACKAGE_NAME}: Tests Passed ----"
fi

echo "PASS: ${PACKAGE_NAME} version ${PACKAGE_VERSION} built and tested successfully."
exit 0
