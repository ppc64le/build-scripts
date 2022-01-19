#!/bin/bash -e
#----------------------------------------------------------------------------
#
# Package		: java-classmate
# Version		: classmate-1.3.4, classmate-1.5.1
# Source repo		: https://github.com/FasterXML/java-classmate
# Tested on		: RHEL 8.4
# Language      	: Java
# Travis-Check  	: True
# Script License	: Apache License Version 2.0
# Maintainer		: Vikas Gupta <vikas.gupta8@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_NAME="java-classmate"
PACKAGE_VERSION=${1:-classmate-1.3.4}
PACKAGE_URL="https://github.com/FasterXML/java-classmate.git"

yum install maven git

export PATH=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.312.b07-2.el8_5.ppc64le/bin/:$PATH
java -version

mkdir -p /home/tester/output
cd /home/tester

# ------- Clone and build source -------

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PKG_VERSION
mvn clean install | tee $LOGS_DIRECTORY/$PKG_NAME-$PKG_VERSION.txt

echo "`date +'%d-%m-%Y %T'` - Installed classmate ---------------------------------------"
echo "- --------------------------------------------------------------------------------------"


