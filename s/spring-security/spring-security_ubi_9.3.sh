#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : spring-security
# Version          : 6.3.1
# Source repo      : https://github.com/spring-projects/spring-security.git
# Tested on        : UBI 9.3
# Language         : Java
# Ci-Check     : True 
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

PACKAGE_NAME=spring-security
PACKAGE_VERSION=${1:-6.3.1}
PACKAGE_URL=https://github.com/spring-projects/spring-security.git

# Install dependencies
yum install -y wget git java-17-openjdk java-17-openjdk-devel

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin/:$PATH
java -version

# Clone spring-security repo
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! ./gradlew publishToMavenLocal && ./gradlew build -x test; then
    echo "Build Fails!"
    exit 1

elif ! ./gradlew test; then
     echo "Test Fails!"
     exit 2
else
    echo "Build and Test Success!"
    exit 0
fi