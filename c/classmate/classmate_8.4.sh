#----------------------------------------------------------------------------
#
# Package		: classmate
# Version		: 1.3.4, 1.5.1
# Source repo		: https://github.com/FasterXML/java-classmate
# Tested on		: RHEL 8.4
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

#!/bin/bash

mkdir -p /logs

# variables
PKG_NAME="classmate"
DIR_NAME="java-classmate"
PKG_VERSION=${1:-1.3.4}
LOGS_DIRECTORY=/logs
LOCAL_DIRECTORY=/home/tester
REPOSITORY="https://github.com/FasterXML/java-classmate.git"


# ------- Clone and build source -------

export PATH=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.312.b07-2.el8_5.ppc64le/bin/:$PATH
java -version
yum install maven

mkdir -p $LOCAL_DIRECTORY
cd $LOCAL_DIRECTORY

git clone $REPOSITORY
cd $DIR_NAME
git checkout $PKG_NAME-$PKG_VERSION
mvn clean install | tee $LOGS_DIRECTORY/$PKG_NAME-$PKG_VERSION.txt

echo "`date +'%d-%m-%Y %T'` - Installed classmate ---------------------------------------"
echo "- --------------------------------------------------------------------------------------"


