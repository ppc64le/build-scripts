#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package        : apache_lucene
# Version        : releases/lucene/9.5.0
# Source repo    : https://github.com/apache/lucene.git
# Tested on      : UBI: 8.5
# Language       : Java
# Script License : Apache License 2.0
# Maintainer     : tirumala_nithya@persistent.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=lucene
PACKAGE_URL= https://github.com/apache/lucene.git
PACKAGE_VERSION=${1:-"releases/lucene/9.5.0"}

yum update -y

#Dependencies

yum install -y java-17-openjdk java-17-openjdk-devel java-17-openjdk-headless git

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk

export PATH=$PATH:$JAVA_HOME/bin

java --version

#Cloning the repository from remote to local

git clone $PACKAGE_URL

cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

#Building and testing Lucene latest release

if ! ./gradlew ; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION| GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! ./gradlew test ; then
    echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION| GitHub  | Fail|  Build_and_Test_fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION| GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi


