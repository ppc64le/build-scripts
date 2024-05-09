#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : jackson-dataformat-xml
# Version          : jackson-dataformat-xml-2.17.0
# Source repo      : https://github.com/FasterXML/jackson-dataformat-xml
# Tested on        : UBI: 9.3
# Language         : Java
# Travis-Check     : True
# Script License   : GNU General Public License v3.0
# Maintainer       : Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=jackson-dataformat-xml
PACKAGE_VERSION=${1:-jackson-dataformat-xml-2.17.0}
PACKAGE_URL=https://github.com/FasterXML/jackson-dataformat-xml

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install git maven java-11-openjdk-devel -y  
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$PATH:$JAVA_HOME/bin

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! mvn install -DskipTests ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
if ! mvn test ; then
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