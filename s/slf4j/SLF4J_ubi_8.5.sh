#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: SLF4J
# Version	: v_1.7.26
# Source repo	: https://github.com/qos-ch/slf4j.git
# Tested on	: UBI 8.5
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Alston Dias <Alston.Dias@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=qos-ch/slf4j
PACKAGE_VERSION=${1:v_1.7.26}
PACKAGE_URL=https://github.com/qos-ch/slf4j.git

yum -y install git java-1.8.0-openjdk java-1.8.0-openjdk-devel java-1.8.0-openjdk-headless maven

git clone --depth=50 --branch=v_1.7.26 $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout -qf $PACKAGE_VERSION


java -Xmx32m -version
javac -J-Xmx32m -version

mvn install -DskipTests=true -Dmaven.javadoc.skip=true -B -V
mvn test -B