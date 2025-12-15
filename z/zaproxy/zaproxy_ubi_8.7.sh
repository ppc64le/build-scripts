#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : zaproxy
# Version          : v2.14.0
# Source repo      : https://github.com/zaproxy/zaproxy.git
# Tested on        : UBI 8.7
# Language         : Java, HTML
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Pooja Shah <Pooja.Shah4@ibm.com>
#
# Disclaimer       : This script has been tested in non-root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=zaproxy
PACKAGE_VERSION=${1:-v2.14.0}
PACKAGE_URL=https://github.com/zaproxy/zaproxy.git
HOME_DIR=${PWD}

sudo yum install -y git wget java-11-openjdk-devel tar lshw binutils nano

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$JAVA_HOME/bin:$PATH
java -version

#Cloning java-jwt repo
cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

if ! ./gradlew -Dorg.gradle.jvmargs=-Xmx4g :zap:distLinux -x test; then
        echo "Build Fails"
        exit 1
elif ! ./gradlew -Dorg.gradle.jvmargs=-Xmx4g test; then
        echo "Test Fails"
        exit 2
else
        cp ./zap/build/distributions/ZAP_${PACKAGE_VERSION:1}_Linux.tar.gz $HOME_DIR/
        ls $HOME_DIR/
        echo "Build and Test Success"
        exit 0
fi