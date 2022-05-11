#!/bin/bash -e
#----------------------------------------------------------------------------
#
# Package       : llvm-project
# Version       : llvmorg-11.0.1
# Source repo   : https://github.com/llvm/llvm-project/
# Tested on     : UBI 8.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : BulkPackageSearch Automation {maintainer}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=llvm-project
PACKAGE_VERSION=llvmorg-11.0.1
PACKAGE_URL=https://github.com/llvm/llvm-project.git

yum -y update && yum install -y git python3 python2 git cmake llvm llvm-devel llvm-googletest

mkdir -p /home/tester/output
cd /home/tester

function build_test_with_python2(){
        SOURCE="Python 2.7"
        cd /home/tester/$PACKAGE_NAME/llvm
        if ! python2 utils/lit/setup.py install; then
                echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
                echo  "$PACKAGE_URL $PACKAGE_NAME " > /home/tester/output/install_fails
                echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail |  Install_Fails" > /home/tester/output/version_tracker
                exit 1
        fi

        cd /home/tester/$PACKAGE_NAME/llvm

        if !  lit --path /usr/bin/lit utils/lit/tests; then
                echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
                echo  "$PACKAGE_URL $PACKAGE_NAME "  > /home/tester/output/test_fails
                echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
                exit 1
        else
                echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
                echo  "$PACKAGE_URL $PACKAGE_NAME "  > /home/tester/output/test_success
                echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
                exit 0
        fi
}

if ! git clone $PACKAGE_URL ; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
                echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
                echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail |  Clone_Fails" > /home/tester/output/version_tracker
        exit 1
fi

cd /home/tester/$PACKAGE_NAME
git checkout $PACKAGE_VERSION
if ! python3 setup.py install; then
    build_test_with_python2
        exit 0
fi

cd /home/tester/$PACKAGE_NAME/llvm

if !  lit --path /usr/bin/lit utils/lit/tests; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo  "$PACKAGE_URL $PACKAGE_NAME "  > /home/tester/output/test_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
        echo  "$PACKAGE_URL $PACKAGE_NAME "  > /home/tester/output/test_success
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
        exit 0
fi