#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: antlr4
# Version	: 4.13.1
# Source repo	: https://github.com/antlr/antlr4
# Tested on	: UBI:9.3
# Language      : Java, Python, C#, C++, Go, Swift
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Mohit Pawar <Mohit.Pawar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=antlr4
PACKAGE_VERSION=${1:-4.13.1}
PACKAGE_URL=https://github.com/antlr/antlr4

yum install -y git wget

yum install -y tzdata java-17-openjdk.ppc64le java-17-openjdk-devel.ppc64le git wget 
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-17)(?=.*ppc64le)')
export PATH=$JAVA_HOME/bin:$PATH

#installing maven 3.8.6
wget http://archive.apache.org/dist/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz
tar -C /usr/local/ -xzvf apache-maven-3.8.6-bin.tar.gz
rm -rf tar xzvf apache-maven-3.8.6-bin.tar.gz
mv /usr/local/apache-maven-3.8.6 /usr/local/maven
export M2_HOME=/usr/local/maven
export PATH=$PATH:$M2_HOME/bin

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
PACKAGE_DIR=`pwd`

cd /usr/local/lib
wget https://www.antlr.org/download/antlr-4.11.1-complete.jar
export CLASSPATH=".:/usr/local/lib/antlr-4.11.1-complete.jar:$CLASSPATH"

export MAVEN_OPTS="-Xmx1G"
alias antlr4='java -Xmx500M -cp "/usr/local/lib/antlr-4.11.1-complete.jar:$CLASSPATH" org.antlr.v4.Tool'
alias grun='java -Xmx500M -cp "/usr/local/lib/antlr-4.11.1-complete.jar:$CLASSPATH" org.antlr.v4.gui.TestRig'

cd ${PACKAGE_DIR}
if ! mvn clean; then
	if ! mvn -DskipTests install; then
	    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	    echo "$PACKAGE_URL $PACKAGE_NAME"
	    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	    exit 1
	fi
fi
cd runtime-testsuite
if ! mvn -Dtest=java.** test; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0

fi
