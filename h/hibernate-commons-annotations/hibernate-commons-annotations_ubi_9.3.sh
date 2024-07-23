#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : hibernate-commons-annotations
# Version          : 7.0.0.Final
# Source repo      : https://github.com/hibernate/hibernate-commons-annotations.git
# Tested on        : UBI 9.3
# Language         : Java
# Travis-Check     : True 
# Script License   : Apache License, Version 2 or later
# Maintainer       : Pooja Shah <Pooja.Shah4@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=hibernate-commons-annotations
PACKAGE_VERSION=${1:-7.0.0.Final}
PACKAGE_URL=https://github.com/hibernate/hibernate-commons-annotations.git

# Install dependencies.
yum install -y yum-utils git wget tar java-11-openjdk-devel

# Clone hibernate-commons-annotations repo
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Update the version of nu.studer:gradle-credentials-plugin
sed -i 's/2.1/2.2/g' build.gradle

if ! ./gradlew clean build -x test; then
    echo "Build Fails!"
    exit 1
elif ! ./gradlew test; then
    echo "Test Fails!"
    exit 2
else
    echo "Build and Test Success!"
    exit 0
fi