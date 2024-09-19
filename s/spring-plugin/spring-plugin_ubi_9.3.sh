#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : spring-plugin
# Version          : 3.0.0
# Source repo      : https://github.com/spring-projects/spring-plugin.git
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

PACKAGE_NAME=spring-plugin
PACKAGE_VERSION=${1:-3.0.0}
PACKAGE_URL=https://github.com/spring-projects/spring-plugin.git

# Install dependencies
yum install -y wget git tar java-17-openjdk java-17-openjdk-devel

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin/:$PATH
java -version

# Clone spring-hateoas repo
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! ./mvnw clean install -DskipTests; then
    echo "Build Fails!"
    exit 1

elif ! ./mvnw test; then
     echo "Test Fails!"
     exit 2
else
    echo "Build and Test Success!"
    exit 0
fi