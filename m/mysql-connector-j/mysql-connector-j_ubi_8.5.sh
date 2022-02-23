#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package       : mysql-connector-j
# Version       : 8.0.28
# Source repo	: https://github.com/mysql/mysql-connector-j.git
# Tested on     : UBI 8.5
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Vikas Kumar <kumar.vikas@in.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=mysql-connector-j
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-8.0.28}
PACKAGE_URL=https://github.com/mysql/mysql-connector-j.git

yum install -y git wget java-1.8.0-openjdk-devel

cd /root
wget https://dlcdn.apache.org//ant/binaries/apache-ant-1.10.12-bin.tar.gz
tar -xzf apache-ant-1.10.12-bin.tar.gz

export PATH=/root/apache-ant-1.10.12/bin/:$PATH

mkdir -p /root/libs
cd /root/libs

wget https://search.maven.org/remotecontent?filepath=org/junit/jupiter/junit-jupiter-engine/5.8.2/junit-jupiter-engine-5.8.2.jar -O junit-jupiter-engine-5.8.2.jar
wget https://search.maven.org/remotecontent?filepath=org/junit/platform/junit-platform-commons/1.8.2/junit-platform-commons-1.8.2.jar -O junit-platform-commons-1.8.2.jar
wget https://search.maven.org/remotecontent?filepath=org/junit/platform/junit-platform-engine/1.8.2/junit-platform-engine-1.8.2.jar -O junit-platform-engine-1.8.2.jar
wget https://search.maven.org/remotecontent?filepath=org/junit/platform/junit-platform-launcher/1.8.2/junit-platform-launcher-1.8.2.jar -O junit-platform-launcher-1.8.2.jar
wget https://search.maven.org/remotecontent?filepath=org/junit/jupiter/junit-jupiter-api/5.8.2/junit-jupiter-api-5.8.2.jar -O junit-jupiter-api-5.8.2.jar
wget https://search.maven.org/remotecontent?filepath=org/apiguardian/apiguardian-api/1.1.2/apiguardian-api-1.1.2.jar -O apiguardian-api-1.1.2.jar
wget https://search.maven.org/remotecontent?filepath=org/opentest4j/opentest4j/1.2.0/opentest4j-1.2.0.jar -O opentest4j-1.2.0.jar
wget https://search.maven.org/remotecontent?filepath=org/javassist/javassist/3.28.0-GA/javassist-3.28.0-GA.jar -O javassist-3.28.0-GA.jar
wget https://search.maven.org/remotecontent?filepath=com/google/protobuf/protobuf-java/3.19.4/protobuf-java-3.19.4.jar -O protobuf-java-3.19.4.jar
wget https://search.maven.org/remotecontent?filepath=org/slf4j/slf4j-api/1.7.35/slf4j-api-1.7.35.jar -O slf4j-api-1.7.35.jar
wget https://search.maven.org/remotecontent?filepath=org/hamcrest/hamcrest/2.2/hamcrest-2.2.jar -O hamcrest-2.2.jar
wget https://search.maven.org/remotecontent?filepath=com/oracle/oci/sdk/oci-java-sdk-common/2.14.1/oci-java-sdk-common-2.14.1.jar -O oci-java-sdk-common-2.14.1.jar

cd /root

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"  
 
fi

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    	exit 0
fi

cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! ant -Dcom.mysql.cj.build.jdk=`which javac | xargs readlink -f | xargs dirname | xargs dirname` -Dcom.mysql.cj.extra.libs=/root/libs dist; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi

# Following test failures have been observed which are in parity with intel platform:
# [junitlauncher] Running testsuite.regression.ConnectionRegressionTest
# [junitlauncher] Tests run: 165, Failures: 3, Aborted: 26, Skipped: 1, Time elapsed: 344.769 sec
# [junitlauncher] Running testsuite.regression.SyntaxRegressionTest
# [junitlauncher] Tests run: 20, Failures: 2, Aborted: 3, Skipped: 0, Time elapsed: 11.819 sec
# [junitlauncher] Running testsuite.simple.ConnectionTest
# [junitlauncher] Tests run: 47, Failures: 1, Aborted: 12, Skipped: 0, Time elapsed: 107.953 sec

# Running the test cases require a running MySql server instance. Currently MySql is not supported on ppc64le.
# As a workaround MySql server instance needs to be run on an x86 machine and the corresponding connection URL needs 
# to be passed to the test case execution.
# Steps:
# 1. Create a MySql server instance as per instructions given on MySql Dockerhub page: (https://hub.docker.com/_/mysql?tab=description)
# docker run --name some-mysql2 -e MYSQL_ROOT_PASSWORD=my-secret-pw -d -p 3306:3306 -p 33060:33060 mysql:8.0.28
#
# 2. Uncomment and replace the hostname of the MySql server in the connection URL in below instructions.

# if ! ant -Dcom.mysql.cj.build.jdk=`which javac | xargs readlink -f | xargs dirname | xargs dirname` -Dcom.mysql.cj.extra.libs=/root/libs -Dcom.mysql.cj.testsuite.url=jdbc:mysql://root:my-secret-pw@<MySql Server host>:3306 -Dcom.mysql.cj.testsuite.mysqlx.url=mysqlx://root:my-secret-pw@<MySql Server host>:33060/test test
# ; then
	# echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
	# echo "$PACKAGE_URL $PACKAGE_NAME" 
	# echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_success_but_test_Fails"
	# exit 1
# else
	# echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
	# echo "$PACKAGE_URL $PACKAGE_NAME"
	# echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
	# exit 0
# fi

