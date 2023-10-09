#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : jruby
# Version       : 9.4.3.0
# Source repo   : https://github.com/jruby/jruby.git
# Tested on     : UBI 8.7
# Language      : Ruby
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=jruby
PACKAGE_VERSION=${1:-9.4.3.0}
PACKAGE_URL=https://github.com/jruby/jruby.git

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
HOME_DIR=${PWD}

yum update -y
yum install -y wget git make gcc java-1.8.0-openjdk-devel

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH
java -version

wget https://dlcdn.apache.org/maven/maven-3/3.8.8/binaries/apache-maven-3.8.8-bin.tar.gz
tar -zxf apache-maven-3.8.8-bin.tar.gz
cp -R apache-maven-3.8.8 /usr/local
ln -s /usr/local/apache-maven-3.8.8/bin/mvn /usr/bin/mvn
mvn -version

wget https://dlcdn.apache.org//ant/binaries/apache-ant-1.9.16-bin.tar.gz
tar -xvzf apache-ant-1.9.16-bin.tar.gz
cp -r `pwd`/apache-ant-1.9.16 /opt/
export ANT_HOME=/opt/apache-ant-1.9.16/
export PATH=$PATH:$ANT_HOME/bin
ant -version

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! ./mvnw ; then
       echo "------------------$PACKAGE_NAME:Build_fails---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
       exit 1
fi

bin/jruby -S bundle install

if ! mvn -Ptest ; then
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