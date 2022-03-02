#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : grails
# Version       : v3.3.11
# Source repo   : https://github.com/grails/grails-core.git
# Tested on     : ubi 8.5
# Language      : JAVA
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vathsala . <vaths367@in.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


HOME_DIR=`pwd`
PACKAGE_NAME=grails-core
PACKAGE_VERSION=${1:-v3.3.11}
PACKAGE_URL=https://github.com/grails/grails-core.git
mkdir -p /home/tester

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

yum install git unzip wget maven -y

#clone the repository
git clone $PACKAGE_URL

export WORK_DIR=$HOME_DIR/$PACKAGE_NAME
cd $WORK_DIR
git checkout $PACKAGE_VERSION

#Tests are in Parity with below mentioned error
#org.grails.compiler.injection.DefaultDomainClassInjectorSpec > initializationError FAILED
#  java.lang.ClassFormatError
#[Thread-4] INFO org.springframework.context.annotation.AnnotationConfigApplicationContext - Closing org.springframework.context.annotation.AnnotationConfigApplicationContext@66db509e: startup date [Wed Mar 02 06:29:27 UTC 2022]; root of context hierarchy

#152 tests completed, 1 failed, 1 skipped
#:grails-core:test FAILED
#FAILURE: Build failed with an exception.

if ! ./gradlew install; then
        echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
        exit 1
fi

if ! ./gradlew test; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
        exit 0
fi

