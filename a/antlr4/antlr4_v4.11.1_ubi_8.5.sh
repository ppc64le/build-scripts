#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: antlr4
# Version	: v4.11.1
# Source repo	: https://github.com/antlr/antlr4
# Tested on	: UBI 8.5
# Language      : Java, Python, C#, C++, Go, Swift
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Muskaan Sheik <Muskaan.Sheik@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=antlr4
PACKAGE_VERSION=v4.11.1
PACKAGE_URL=https://github.com/antlr/antlr4

yum install -y git wget

yum install -y java-11-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.17.0.8-2.el8_6.ppc64le

wget https://archive.apache.org/dist/maven/maven-3/3.8.5/binaries/apache-maven-3.8.5-bin.tar.gz
tar -C /usr/local/ -xzvf apache-maven-3.8.5-bin.tar.gz
rm -rf tar xzvf apache-maven-3.8.5-bin.tar.gz
mv /usr/local/apache-maven-3.8.5 /usr/local/maven
export M2_HOME=/usr/local/maven
export PATH=$PATH:$M2_HOME/bin

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

cd /usr/local/lib
wget https://www.antlr.org/download/antlr-4.11.1-complete.jar
export CLASSPATH=".:/usr/local/lib/antlr-4.11.1-complete.jar:$CLASSPATH"
cd /

export MAVEN_OPTS="-Xmx1G"
alias antlr4='java -Xmx500M -cp "/usr/local/lib/antlr-4.11.1-complete.jar:$CLASSPATH" org.antlr.v4.Tool'
alias grun='java -Xmx500M -cp "/usr/local/lib/antlr-4.11.1-complete.jar:$CLASSPATH" org.antlr.v4.gui.TestRig'

cd antlr4/
if ! mvn clean; then
	if ! mvn -DskipTests install; then
		echo "Build fails"
		exit 2
	fi
fi
cd runtime-testsuite
if ! mvn -Dtest=java.** test; then
	echo "Test fails"
	exit 2
else
	echo "Build and test success"
	exit 0
fi
