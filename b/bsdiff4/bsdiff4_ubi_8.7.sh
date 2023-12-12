#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : bsdiff4
# Version          : 1.2.4
# Source repo      : https://github.com/ilanschnell/bsdiff4
# Tested on        : UBI 8.7
# Language         : C,Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=bsdiff4
PACKAGE_VERSION=${1:-1.2.4}
PACKAGE_URL=https://github.com/ilanschnell/bsdiff4
HOME_DIR=${PWD}

yum install git wget gcc gcc-c++ python39 python39-pip python39-devel yum-utils make automake autoconf libtool gdb* binutils rpm-build gettext  -y

# Install pip and activate venv
python3 -m ensurepip --upgrade
export PATH=$PATH:/usr/local/bin

pip3 install pytest

# Clone package repository
cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install
if !  python3 -m pip install -e .; then
        echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
        exit 1
fi

# Test
python3 -m pip install bsdiff4[test]
if ! pytest ; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
        exit 2
else
        echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_and_Test_Success"
        exit 0
fi
