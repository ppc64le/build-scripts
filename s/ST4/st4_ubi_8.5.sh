#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : ST4
# Version       : 4.3.1
# Source repo   : https://github.com/antlr/stringtemplate4.git
# Tested on     : UBI: 8.5
# Language      : Java
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer's  : Balavva Mirji <Balavva.Mirji@ibm.com>
#
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

PACKAGE_NAME=ST4
PACKAGE_VERSION=${1:-4.3.1}              
PACKAGE_URL=https://github.com/antlr/stringtemplate4.git

# install dependencies
yum install -y git wget java-1.8.0-openjdk-devel 

# install maven
wget https://dlcdn.apache.org/maven/maven-3/3.8.4/binaries/apache-maven-3.8.4-bin.tar.gz
tar -zxvf apache-maven-3.8.4-bin.tar.gz
mv apache-maven-3.8.4 /opt/maven
export M2_HOME=/opt/maven
export PATH=${M2_HOME}/bin:${PATH}

# clone package
cd $WORK_DIR
git clone $PACKAGE_URL
cd stringtemplate4
git checkout $PACKAGE_VERSION

# to build
mvn install -DskipTests=true 

# to execute tests
mvn test
<< test_error
Tests in error:
  testBugArrayIndexOutOfBoundsExceptionInSTRuntimeMessage_getSourceLocation(org.stringtemplate.v4.test.TestEarlyEvaluation): (..)
  testEarlyEval2(org.stringtemplate.v4.test.TestEarlyEvaluation): (..)
  testEarlyEval(org.stringtemplate.v4.test.TestEarlyEvaluation): (..)
  testGroupStringMultipleThreads(org.stringtemplate.v4.test.TestGroups): org.junit.ComparisonFailure: expected:<x=[99]; // foo> but was:<x=[]; // foo>

Tests run: 629, Failures: 0, Errors: 4, Skipped: 2

Observed above 4 errors which are in parity with x86.
test_error