#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : jena-arq
# Version       : jena-4.9.0
# Source repo   : https://github.com/apache/jena/tree/main/jena-arq
# Tested on     : UBI: 9.3
# Travis-Check : True
# Script License: Apache License 2.0
# Maintainer's  : Mayur Bhosure <Mayur.Bhosure2@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


# Variables
REPO=https://github.com/apache/jena.git
VERSION=jena-4.9.0
DIR=jena/jena-arq

# install tools and dependent packages
yum update -y
yum install -y git wget

# install java
yum -y install java-1.8.0-openjdk-devel

#install maven
MAVEN_VERSION=${MAVEN_VERSION:-3.8.8}
wget https://downloads.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz
tar -C /usr/local/ -xzf apache-maven-$MAVEN_VERSION-bin.tar.gz
mv /usr/local/apache-maven-$MAVEN_VERSION /usr/local/maven
export M2_HOME=/usr/local/maven 

# update the path env. variable
export PATH=$PATH:$M2_HOME/bin


# Cloning the repository from remote to local
cd /home
git clone $REPO
cd $DIR
git checkout $VERSION

# Build and test package
if ! mvn -B clean install -Dmaven.javadoc.skip=true -fae ; then
    echo "------------------$DIR:Install_fails-------------------------------------"
    echo "$REPO $DIR"
    echo "$DIR  |  $REPO | $VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi 

#Test
if ! mvn test -DforkCount=2 ; then
    echo "------------------$DIR:Install_success_but_test_fails---------------------"
    echo "$REPO $DIR"
    echo "$DIR  |  $REPO | $VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$DIR:Install_&_test_both_success-------------------------"
    echo "$REPO $DIR"
    echo "$DIR  |  $REPO | $VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
