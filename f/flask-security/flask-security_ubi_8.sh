#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : flask-security
# Version       : 4.1.2
# Source repo   : https://github.com/Flask-Middleware/flask-security.git
# Tested on     : UBI 8.4
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vaishnavi Patil <Vaishnavi.Patil3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#   
# ----------------------------------------------------------------------------
PACKAGE_NAME=flask-security
PACKAGE_VERSION=${1:-4.1.2}
PACKAGE_URL=https://github.com/Flask-Middleware/flask-security.git
PACKAGE_FOLDER=flask-security

yum install -y git python38 python38-devel gcc libffi libffi-devel libpq-devel cmake redhat-rpm-config openssl-devel cargo python3-devel sqlite

mkdir -p /home/tester/output

ln -s /usr/bin/python3.8 /usr/bin/python
ln -s /usr/bin/pip3.8 /usr/bin/pip

cd /home/tester 

if ! git clone $PACKAGE_URL ; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
				echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
                echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | Fail |  Clone_Fails" > /home/tester/output/version_tracker
        exit 1
fi


cd /home/tester/$PACKAGE_FOLDER

echo " --------------------------------- checkout version  $PACKAGE_VERSION ------------------------------------"
git checkout $PACKAGE_VERSION



echo " --------------------------------- installing requirements ------------------------------------"
pip install -r requirements/dev.txt
python setup.py build_sphinx
python setup.py compile_catalog

if ! pytest ; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo  "$PACKAGE_URL $PACKAGE_NAME "  > /home/tester/output/test_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION |  Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
        echo  "$PACKAGE_URL $PACKAGE_NAME "  > /home/tester/output/test_success
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION |  Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
        exit 0
fi


