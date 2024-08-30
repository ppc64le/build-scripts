#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package       : mysql-connector-j
# Version       : 9.0.0
# Source repo	: https://github.com/mysql/mysql-connector-j.git
# Tested on     : UBI 9.3
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Siddesh Sangodkar <siddesh.sangodkar1@ibm.com>
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
PACKAGE_VERSION=${1:-9.0.0}
PACKAGE_URL=https://github.com/mysql/mysql-connector-j.git

yum install -y git wget java-1.8.0-openjdk-devel

export WORKDIR=$PWD
cd $WORKDIR
wget https://dlcdn.apache.org//ant/binaries/apache-ant-1.10.15-bin.tar.gz
tar -xzf apache-ant-1.10.15-bin.tar.gz

export PATH=$WORKDIR/apache-ant-1.10.15/bin/:$PATH

mkdir -p $WORKDIR/libs
cd $WORKDIR/libs

# We need to install these binaries individually as per the instructions at https://dev.mysql.com/doc/connector-j/8.0/en/connector-j-installing-source.html
wget https://search.maven.org/remotecontent?filepath=org/junit/jupiter/junit-jupiter-api/5.10.2/junit-jupiter-api-5.10.2.jar -O junit-jupiter-api-5.10.2.jar
wget https://search.maven.org/remotecontent?filepath=org/junit/jupiter/junit-jupiter-engine/5.10.2/junit-jupiter-engine-5.10.2.jar -O junit-jupiter-engine-5.10.2.jar

wget https://search.maven.org/remotecontent?filepath=org/junit/platform/junit-platform-commons/1.10.2/junit-platform-commons-1.10.2.jar -O junit-platform-commons-1.10.2.jar
wget https://search.maven.org/remotecontent?filepath=org/junit/platform/junit-platform-engine/1.10.2/junit-platform-engine-1.10.2.jar -O junit-platform-engine-1.10.2.jar
wget https://search.maven.org/remotecontent?filepath=org/junit/platform/junit-platform-launcher/1.10.2/junit-platform-launcher-1.10.2.jar -O junit-platform-launcher-1.10.2.jar

wget https://search.maven.org/remotecontent?filepath=org/apiguardian/apiguardian-api/1.1.2/apiguardian-api-1.1.2.jar -O apiguardian-api-1.1.2.jar
wget https://search.maven.org/remotecontent?filepath=org/opentest4j/opentest4j/1.3.0/opentest4j-1.3.0.jar -O opentest4j-1.3.0.jar

wget https://search.maven.org/remotecontent?filepath=org/javassist/javassist/3.30.2-GA/javassist-3.30.2-GA.jar -O javassist-3.30.2-GA.jar
wget https://search.maven.org/remotecontent?filepath=com/google/protobuf/protobuf-java/4.27.2/protobuf-java-4.27.2.jar -O protobuf-java-4.27.2.jar
wget https://search.maven.org/remotecontent?filepath=com/mchange/c3p0/0.10.1/c3p0-0.10.1.jar -O c3p0-0.10.1.jar
wget https://search.maven.org/remotecontent?filepath=org/slf4j/slf4j-api/2.0.13/slf4j-api-2.0.13.jar -O slf4j-api-2.0.13.jar
wget https://search.maven.org/remotecontent?filepath=org/hamcrest/hamcrest/2.2/hamcrest-2.2.jar -O hamcrest-2.2.jar
wget https://search.maven.org/remotecontent?filepath=io/opentelemetry/opentelemetry-api/1.38.0/opentelemetry-api-1.38.0.jar -O opentelemetry-api-1.38.0.jar
wget https://search.maven.org/remotecontent?filepath=io/opentelemetry/opentelemetry-context/1.38.0/opentelemetry-context-1.38.0.jar -O opentelemetry-context-1.38.0.jar
wget https://search.maven.org/remotecontent?filepath=org/opentest4j/opentest4j/1.3.0/opentest4j-1.3.0.jar -O opentest4j-1.3.0.jar
wget https://search.maven.org/remotecontent?filepath=com/oracle/oci/sdk/oci-java-sdk-common/3.41.2/oci-java-sdk-common-3.41.2.jar -O oci-java-sdk-common-3.41.2.jar

cd $WORKDIR

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
	exit 1
fi

cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! ant -Dcom.mysql.cj.build.jdk=`which javac | xargs readlink -f | xargs dirname | xargs dirname` -Dcom.mysql.cj.extra.libs=$WORKDIR/libs build; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi

# Test failures have been observed which are in parity with intel platform:

# Running the test cases require a running MySql server instance. Currently MySql is not supported on ppc64le.
# As a workaround MySql server instance needs to be run on an x86 machine and the corresponding connection URL needs 
# to be passed to the test case execution.
# Steps:
# 1. Create a MySql server instance as per instructions given on MySql Dockerhub page: (https://hub.docker.com/_/mysql?tab=description)
# docker run --name some-mysql2 -e MYSQL_ROOT_PASSWORD=my-secret-pw -d -p 3306:3306 -p 33060:33060 mysql:8.0.28
#
# 2. Uncomment and replace the hostname of the MySql server in the connection URL in below instructions.

# if ! ant -Dcom.mysql.cj.build.jdk=`which javac | xargs readlink -f | xargs dirname | xargs dirname` -Dcom.mysql.cj.extra.libs=$WORKDIR/libs -Dcom.mysql.cj.testsuite.url=jdbc:mysql://root:my-secret-pw@<MySql Server host>:3306 -Dcom.mysql.cj.testsuite.mysqlx.url=mysqlx://root:my-secret-pw@<MySql Server host>:33060/test test
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
exit 0
