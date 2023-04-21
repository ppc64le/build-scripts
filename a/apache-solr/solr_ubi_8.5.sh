#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : solr
# Version          : releases/solr/9.2.0
# Source repo      : https://github.com/apache/solr
# Tested on        : UBI 8.5
# Language         : Java
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Shubham Garud <Shubham.Garud@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=solr
PACKAGE_VERSION=${1:-releases/solr/9.2.0}
PACKAGE_URL=https://github.com/apache/solr

# Install dependencies
yum install -y wget git java-11-openjdk java-11-openjdk-devel

java -XshowSettings:properties -version 2>&1 > /dev/null | grep 'java.home'

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.18.0.10-2.el8_7.ppc64le
export PATH=/usr/lib/jvm/java-11-openjdk-11.0.12.0.7-0.el8_4.ppc64le/bin/:$PATH


git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

chmod +x gradlew

if ! ./gradlew localSettings; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! ./gradlew test; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi

