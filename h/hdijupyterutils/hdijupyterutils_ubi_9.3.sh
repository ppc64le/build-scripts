#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : hdijupyterutils
# Version          : main
# Source repo      : https://github.com/jupyter-incubator/sparkmagic.git
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Aastha Sharma <aastha.sharma4@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=hdijupyterutils
PACKAGE_VERSION=${1:-0.20.0}
PACKAGE_URL=https://github.com/jupyter-incubator/sparkmagic.git
INSTALL_DIR="/sparkmagic"
PACKAGE_PATH="$INSTALL_DIR/$PACKAGE_NAME"


# Install dependencies
yum install -y git gcc gcc-c++ make wget openssl-devel bzip2-devel libffi-devel zlib-devel python-devel python-pip krb5-devel

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_PATH
git checkout $PACKAGE_VERSION

# install necessay dependencies
pip install pytest mock build
pip install -r requirements.txt

#install
if ! (python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#run tests  
if !(pytest -k "not test_send_to_handler"); then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi
