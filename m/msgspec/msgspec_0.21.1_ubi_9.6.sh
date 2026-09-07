#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : msgspec
# Version          : 0.21.1
# Source repo      : https://github.com/jcrist/msgspec
# Tested on	   : UBI:9.6
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Prerna Kumbhar <Prerna.Kumbhar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=msgspec
PACKAGE_VERSION=${1:-0.21.1}
PACKAGE_URL=https://github.com/jcrist/msgspec
PACKAGE_DIR=msgspec

dnf install -y git gcc gcc-c++ make openssl-devel bzip2-devel libffi-devel zlib-devel xz-devel wget tar sqlite-devel python3.11 python3.11-pip python3.11-devel
ln -sf /usr/bin/python3.11 /usr/bin/python3
ln -sf /usr/bin/pip3.11 /usr/bin/pip
ln -sf /usr/bin/pip3.11 /usr/bin/pip3

pip3 install pytest pyright mypy

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME  
git checkout $PACKAGE_VERSION

if ! pip install -e .; then
        echo "------------------$PACKAGE_NAME:install_fails------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_Failed"  
        exit 1
fi

# Run pytest
pytest
if [ $? -eq 0 ]; then
    echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Pass | Both_Install_and_Test_Success"
    exit 0
else
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_success_but_test_Fails"
    exit 2
fi
