#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	    : j2objc-annotations
# Version	    : 1.3
# Source repo	: https://github.com/google/j2objc.git
# Tested on	    : UBI 8.3
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Srividya Chittiboina <Srividya.Chittiboina@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

WORK_DIR=`pwd`

PACKAGE_NAME=j2objc/annotations
PACKAGE_VERSION=${1:-1.3}
PACKAGE_URL=https://github.com/google/j2objc.git

yum install git java-1.8.0-openjdk-devel maven -y

#clone repo
cd $WORK_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

mvn -Dgpg.skip=true clean install
mvn test