#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package	: azure-cli-core
# Version	: 2.0.35
# Source repo	: https://github.com/Azure/azure-cli
# Tested on	: UBI 8.4
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Vaibhav Bhadade {vaibhav.bhadade@ibm.com}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=azure-cli-core
PACKAGE_VERSION=${1:-azure-cli-2.0.35}
PACKAGE_URL=${2:-https://github.com/Azure/azure-cli}
PACKAGE_FOLDER=azure-cli

yum install -y  python3 python3-devel  ncurses git libffi libffi-devel  make cmake openssl-devel libyaml-devel

mkdir -p /home/tester/output

python3 -m pip install mock pytest pytest-cov setuptools-rust mccabe==0.6.0
cd /home/tester
ln -s /usr/bin/python3 /usr/bin/python

echo "Cloning pacakge $PACKAGE_URL"
if ! git clone $PACKAGE_URL ; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
                echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
                echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail |  Clone_Fails" > /home/tester/output/version_tracker
        exit 1
fi

echo " --------------------------------- checkout version  $PACKAGE_VERSION ------------------------------------"

cd /home/tester/$PACKAGE_FOLDER
git checkout $PACKAGE_VERSION
python3 scripts/dev_setup.py

cd src/$PACKAGE_NAME

if ! python3 setup.py install; then
         exit 0
fi


if ! pytest; then
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


