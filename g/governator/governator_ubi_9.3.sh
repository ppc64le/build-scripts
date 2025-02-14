#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : governator
# Version          : v1.17.13
# Source repo      : https://github.com/Netflix/governator.git
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

PACKAGE_NAME=governator
PACKAGE_VERSION=${1:-v1.17.13}
PACKAGE_URL=https://github.com/Netflix/governator.git

# Install dependencies
yum install -y wget git tar java-11-openjdk java-11-openjdk-devel

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$JAVA_HOME/bin/:$PATH
java -version

# Clone governator repo
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

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