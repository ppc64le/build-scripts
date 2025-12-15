#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package               : tomcat
# Version               : 11.0.0-M26
# Source repo           : https://github.com/apache/tomcat
# Tested on             : UBI:9.3
# Language              : Java
# Ci-Check          : True
# Script License        : Apache License 2.0 or later
# Maintainer            : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_VERSION=${1:-11.0.0-M26}
PACKAGE_NAME=tomcat
PACKAGE_URL=https://github.com/apache/tomcat

yum install -y unzip git wget gcc-c++ gcc java-17-openjdk java-17-openjdk-devel java-17-openjdk-headless

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$PATH:$JAVA_HOME

#install ant
wget -c https://mirrors.advancedhosters.com/apache/ant/binaries/apache-ant-1.10.14-bin.zip
unzip apache-ant-*.zip
mv apache-ant-*/ /usr/local/ant
export ANT_HOME="/usr/local/ant"
export PATH="$PATH:/usr/local/ant/bin"

git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

if ! ant ; then
     echo "------------------$PACKAGE_NAME:Build_fails---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails_"
     exit 1
fi

if ! ant test ; then
      echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_and_Test_fails"
      exit 2
else
      echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
      exit 0
fi
