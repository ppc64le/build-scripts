#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : azure-mgmt-batch
# Version       : 5.0.1
# Source repo   : https://github.com/Azure/azure-sdk-for-python
# Tested on	: UBI 8.5
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Vaibhav Bhadade <vaibhav.bhadade@ibm.com> 
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=azure-mgmt-batch
PACKAGE_VERSION=${1:-azure-mgmt-batch_5.0.1}
PACKAGE_URL=${2:-https://github.com/Azure/azure-sdk-for-python}
PACKAGE_FOLDER=azure-sdk-for-python

yum install -y git  python3 python3-devel make rust-toolset openssl openssl-devel libffi libffi-devel 

mkdir -p /home/tester/output

python3 -m pip install pytest pytest-cov setuptools-rust 


cd /home/tester 


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

cd $PACKAGE_NAME

if ! python3 setup.py install; then
         exit 0
fi


if ! pytest ; then
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

