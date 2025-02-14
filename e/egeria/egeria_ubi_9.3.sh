#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: egeria
# Version	: V4.3
# Source repo	: https://github.com/odpi/egeria.git
# Tested on	: UBI: 9.3
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Pooja Shah <Pooja.Shah4@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=egeria
PACKAGE_VERSION=${1:-V4.3}
PACKAGE_URL=https://github.com/odpi/egeria.git

yum install -y git wget tar java-17-openjdk-devel openssl-devel

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH
java -version

#Cloning egeria repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

export LC_ALL=C.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

if ! ./gradlew clean build -x test; then
        echo "Build Fails"
	exit 1
elif ! ./gradlew test -x :open-metadata-test:open-metadata-fvt:view-services-fvt:glossary-author-fvt:test -Dorg.gradle.jvmargs="-Xmx2048m"; then
        echo "Test Fails"
        exit 2
else
        echo "Build and Test Success"
        exit 0
fi

# Note: :open-metadata-test:open-metadata-fvt:view-services-fvt:glossary-author-fvt:test fails on both ppc64le and x86-64.
# Hence, we are skipping it for now. We will revisit it once the issue is fixed by https://github.com/odpi/egeria/issues/8301