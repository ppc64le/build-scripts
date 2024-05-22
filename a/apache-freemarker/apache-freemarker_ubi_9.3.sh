#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : apache-freemarker
# Version       : v2.3.32
# Source repo   : https://github.com/apache/freemarker
# Tested on     : UBI: 9.3
# Language      : Java
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

PACKAGE_NAME=apache-freemarker
PACKAGE_VERSION=${1:-v2.3.32}
PACKAGE_URL=https://github.com/apache/freemarker

yum -y update
yum -y install java-1.8.0-openjdk-devel wget git 

wget https://dlcdn.apache.org//ant/binaries/apache-ant-1.10.13-bin.tar.gz
tar xvfvz apache-ant-1.10.13-bin.tar.gz -C /opt
ln -s /opt/apache-ant-1.10.13 /opt/ant
sh -c 'echo ANT_HOME=/opt/ant >> /etc/environment'
ln -s /opt/ant/bin/ant /usr/bin/ant

wget https://dlcdn.apache.org//ant/ivy/2.5.2/apache-ivy-2.5.2-bin.tar.gz
tar xvfvz apache-ivy-2.5.2-bin.tar.gz -C /opt/ant/lib

wget https://dlcdn.apache.org//commons/lang/binaries/commons-lang3-3.14.0-bin.tar.gz
tar xvfvz commons-lang3-3.14.0-bin.tar.gz  -C /opt/ant/lib

git clone $PACKAGE_URL
cd freemarker/
git checkout $PACKAGE_VERSION

ant download-ivy

if ! ant ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

echo "1i boot.classpath.j2se1.8=/usr/lib/jvm/jre/lib/rt.jar" > build.properties

if ! ant test ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
