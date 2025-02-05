#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package        : jpype
# Version        : v1.5.0
# Source repo    : https://github.com/jpype-project/jpype.git
# Tested on      : UBI 9.3
# Language       : Python
# Travis-Check   : True
# Script License : Apache License, Version 2 or later
# Maintainer     : Vivek Sharma <vivek.sharma20@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such cases, please
#             contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=jpype
PACKAGE_VERSION=${1:-v1.5.0}
PACKAGE_DIR=jpype
PACKAGE_URL=https://github.com/jpype-project/jpype.git

# Install necessary system packages
yum install -y git python-devel gcc gcc-c++ gzip tar make wget xz cmake yum-utils openssl-devel openblas-devel bzip2-devel bzip2 zip unzip libffi-devel zlib-devel autoconf automake libtool cargo pkgconf-pkg-config.ppc64le info.ppc64le fontconfig.ppc64le fontconfig-devel.ppc64le sqlite-devel

# Set JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$JAVA_HOME/bin:$PATH

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

# Download JDBC Drivers
wget https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.42.0.0/sqlite-jdbc-3.42.0.0.jar -O sqlite-jdbc.jar
wget https://repo1.maven.org/maven2/org/hsqldb/hsqldb/2.7.2/hsqldb-2.7.2.jar -O hsqldb.jar
wget https://repo1.maven.org/maven2/com/h2database/h2/2.2.224/h2-2.2.224.jar -O h2.jar

# Add drivers to CLASSPATH
export CLASSPATH=$CLASSPATH:$(pwd)/sqlite-jdbc.jar:$(pwd)/hsqldb.jar:$(pwd)/h2.jar

# Install test dependencies
pip3 install pytest pytest-cov numpy

# Install the package
if ! pip3 install .; then
    echo "------------------$PACKAGE_NAME: Installation successful ---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Installation_Success"
    exit 1
fi

# Run tests
if ! tox -e py3; then
    echo "------------------$PACKAGE_NAME: Tests failed ------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Tests_Failure"
    exit 0
fi
