#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : netty
# Version       : netty-4.1.84.Final
# Language      : Java
# Source repo   : https://github.com/netty/netty
# Tested on     : UBI 8.5
# Travis-Check  : True
# Script License: Apache-2.0 License
# Maintainer    : Mohit Pawar <mohit.pawar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

#Variables
PACKAGE_URL=https://github.com/netty/netty.git
PACKAGE_VERSION="${1:-netty-4.1.84.Final}"

#Install required files
yum install -y git maven
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

#Cloning Repo
git clone $PACKAGE_URL
cd netty/transport/
git checkout $PACKAGE_VERSION

git branch

#Build and test package
if ! mvn install ; then
    echo "------------------$PACKAGE_NAME::install_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  install_fails"
    exit 1
fi

if ! mvn test ; then
    echo "------------------$PACKAGE_NAME::test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  test_fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME::Install_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
