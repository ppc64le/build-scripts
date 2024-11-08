#!/bin/bash -e   
# ----------------------------------------------------------------------------
#
# Package       : undertow
# Version       : 2.3.18.Final
# Source repo   : https://github.com/undertow-io/undertow
# Tested on     : UBI: 9.3
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : kotla santhosh<kotla.santhosh@ibm.com>
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
PACKAGE_NAME=undertow
PACKAGE_URL=https://github.com/undertow-io/undertow.git
PACKAGE_VERSION=${1:-2.3.18.Final}


# install tools and dependent packages
yum install -y git wget java-11-openjdk-devel sudo
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$JAVA_HOME/bin:$PATH

# install maven
MAVEN_VERSION=${MAVEN_VERSION:-3.8.8}
wget https://downloads.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz
tar -C /usr/local/ -xzf apache-maven-$MAVEN_VERSION-bin.tar.gz
mv /usr/local/apache-maven-$MAVEN_VERSION /usr/local/maven
export M2_HOME=/usr/local/maven
 
# update the path env. variable
export PATH=$PATH:$M2_HOME/bin


# Cloning the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Build

if ! mvn -U -B -fae -DskipTests -Dfindbugs clean install ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi 
sudo bash -c "echo '127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4' > /etc/hosts"

if ! mvn -U -B -fae test -Pproxy '-DfailIfNoTests=false' -pl -:core,-:servlet,-:websockets-jsr  -Dtest.ipv6=true ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
