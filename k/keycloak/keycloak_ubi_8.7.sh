#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package	: keycloak
# Version	: 22.0.4
# Source repo	: https://github.com/keycloak/keycloak.git
# Tested on	: ubi 8.7
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Chandranana Naik <Naik.Chandranana@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


PACKAGE_NAME=keycloak
PACKAGE_VERSION=${1:-22.0.4}
PACKAGE_URL=https://github.com/keycloak/keycloak.git

OS_NAME=`cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f2 | tr -d '"'`

#Dependencies installation
yum install -y git wget tar bzip2 vim java-17-openjdk.ppc64le java-17-openjdk-devel.ppc64le
java -version

#install maven
cd ${PWD}
wget https://archive.apache.org/dist/maven/maven-3/3.9.1/binaries/apache-maven-3.9.1-bin.tar.gz
tar -xvf apache-maven-3.9.1-bin.tar.gz
export PATH=$PATH:${PWD}/apache-maven-3.9.1/bin
mvn --version

#install Phantomjs
cd ${PWD}
wget  https://github.com/ibmsoe/phantomjs/releases/download/2.1.1/phantomjs-2.1.1-linux-ppc64.tar.bz2
tar -xvf phantomjs-2.1.1-linux-ppc64.tar.bz2 -C /usr/local 
export PATH=$PATH:/usr/local/phantomjs-2.1.1-linux-ppc64/bin

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-17.0.9.0.9-2.el8.ppc64le/
export PATH=$JAVA_HOME/bin:$PATH

#cloning repo
cd ${PWD}
git clone https://github.com/keycloak/keycloak.git
cd keycloak
git checkout $PACKAGE_VERSION

#Build Keycloak

if ! mvn -Dmaven.test.skip=true clean install -e ; then
       echo "------------------$PACKAGE_NAME:Build_fails---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
       exit 1
fi

echo "============== $PACKAGE_NAME Build successful =============="

echo "Testing Unit Tests"
SEP=""
PROJECTS=""
for i in `find -name '*Test.java' -type f | egrep -v './(testsuite|quarkus)/' | sed 's|/src/test/java/.*||' | sort | uniq | sed 's|./||'`; do
  if [ "$i" == "crypto/fips1402" ]
  then
	continue;
  elif [ "$i" == "docs/documentation/tests" ]
  then
		continue;
  fi

  PROJECTS="$PROJECTS$SEP$i"
  SEP=","
done

if ! mvn test -nsu -B -pl "$PROJECTS" -am; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
	exit 2
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi

#TO DO: Disabling integration tests for now, due to intermittent failures.
#echo "Testing basetest1"
#TESTS=`testsuite/integration-arquillian/tests/base/testsuites/base-suite.sh 1`
#echo "Tests: $TESTS"
#mvn test -Dsurefire.rerunFailingTestsCount=2 -nsu -B -Pauth-server-quarkus -Dtest=$TESTS -pl testsuite/integration-arquillian/tests/base | misc/log/trimmer.sh

#echo "Testing basetest2"
#TESTS=`testsuite/integration-arquillian/tests/base/testsuites/base-suite.sh 2`
#TESTS=$(echo "$TESTS" | sed 's/,[^,]*$//') #org.keycloak.testsuite.broker.** tests are skipped due to chromedriver dependency
#echo "Tests: $TESTS"
#mvn test -Dsurefire.rerunFailingTestsCount=2 -nsu -B -Pauth-server-quarkus -Dtest=$TESTS -pl testsuite/integration-arquillian/tests/base | misc/log/trimmer.sh

#echo "Testing basetest3"
#TESTS=`testsuite/integration-arquillian/tests/base/testsuites/base-suite.sh 3`
#echo "Tests: $TESTS"
#mvn test -Dsurefire.rerunFailingTestsCount=2 -nsu -B -Pauth-server-quarkus -Dtest=$TESTS -pl testsuite/integration-arquillian/tests/base | misc/log/trimmer.sh

#echo "Testing basetest4"
#TESTS=`testsuite/integration-arquillian/tests/base/testsuites/base-suite.sh 4`
#TESTS=$(echo "$TESTS" | sed 's/,[^,]*$//')  #**,org.keycloak.testsuite.x509.** tests are skipped due to phantomjs crash.
#echo "Tests: $TESTS"
#mvn test -Dsurefire.rerunFailingTestsCount=2 -nsu -B -Pauth-server-quarkus -Dtest=$TESTS -pl testsuite/integration-arquillian/tests/base | misc/log/trimmer.sh

#echo "Testing basetest5"
#TESTS=`testsuite/integration-arquillian/tests/base/testsuites/base-suite.sh 5`
#TESTS=$(echo "$TESTS" | sed 's/,[^,]*$//') #**,org.keycloak.testsuite.javascript.** tests are skipped due to chromedriver dependency
#echo "Tests: $TESTS"
#mvn test -Dsurefire.rerunFailingTestsCount=2 -nsu -B -Pauth-server-quarkus -Dtest=$TESTS -pl testsuite/integration-arquillian/tests/base | misc/log/trimmer.sh

#echo "Testing basetest6"
#TESTS=`testsuite/integration-arquillian/tests/base/testsuites/base-suite.sh 6`
#echo "Tests: $TESTS"
#mvn test -Dsurefire.rerunFailingTestsCount=2 -nsu -B -Pauth-server-quarkus -Dtest=$TESTS -pl testsuite/integration-arquillian/tests/base | misc/log/trimmer.sh



