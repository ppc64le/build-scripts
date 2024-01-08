#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : orientdb
# Version       : 3.2.20
# Source repo   : https://github.com/orientechnologies/orientdb.git
# Tested on     : UBI: 8.7
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Pooja Shah <Pooja.Shah4@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=orientdb
PACKAGE_VERSION=${1:-3.2.20}
PACKAGE_URL=https://github.com/orientechnologies/orientdb.git
HOME_DIR=${PWD}

yum update -y
yum install -y git wget tar openssl-devel freetype fontconfig

# Install IBM Semeru Runtime Java 11
cd $HOME_DIR
wget https://github.com/ibmruntimes/semeru11-certified-binaries/releases/download/jdk-11.0.18%2B10_openj9-0.36.1/ibm-semeru-certified-jdk_ppc64le_linux_11.0.18.0.tar.gz
tar -zxf ibm-semeru-certified-jdk_ppc64le_linux_11.0.18.0.tar.gz

export JAVA_HOME=$HOME_DIR/jdk-11.0.18+10
export PATH=$JAVA_HOME/bin:$PATH
java -version

#Cloning jnr-posix repo
cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

export MAVEN_OPTS="-Xmx2g"

if ! ./mvnw clean install -DskipTests -Dpolyglot.engine.WarnInterpreterOnly=false; then
	echo "Build Fails"
	exit 1
elif ! ./mvnw test -Dpolyglot.engine.WarnInterpreterOnly=false; then
	echo "Test Fails"
	exit 2
else
	echo "Build and Test Success"
	exit 0
fi