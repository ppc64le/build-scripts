#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : esapi-java-legacy
# Version       : esapi-2.2.3.0
# Source repo   : https://github.com/ESAPI/esapi-java-legacy.git
# Tested on     : UBI 8.5
# Language      : Java
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : BulkPackageSearch Automation {maintainer}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=esapi-java-legacy
PACKAGE_VERSION=esapi-2.2.3.0
PACKAGE_URL=https://github.com/ESAPI/esapi-java-legacy.git

yum install -y git wget gcc-c++ pinentry maven
yum -y update --allowerasing --skip-broken --nobest

rm -rf $PACKAGE_NAME

git clone $PACKAGE_URL

cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

export GPG_TTY=$(tty)

if ! (mvn install && mvn test) ; then
                        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
                        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master  | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
                        exit 0
                else
                        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
                        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
                        exit 0
                fi

