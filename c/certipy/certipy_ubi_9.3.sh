#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : certipy
# Version          : main
# Source repo      : https://github.com/LLNL/certipy.git
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

#variables
PACKAGE_NAME=certipy
PACKAGE_VERSION=${1:-main}
PACKAGE_URL=https://github.com/LLNL/certipy.git

#install dependencies
yum install -y --allowerasing yum-utils git gcc gcc-c++ make curl python3.11 python3.11-pip python3.11-devel openssl-devel pkg-config

python3.11 -m venv cert-venv
source cert-venv/bin/activate

# clone repository
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"

python3.11 -m pip install --upgrade pip
python3.11 -m pip install build
python3.11 -m pip install wheel
python3.11 -m pip install setuptools wheel pypandoc requests flask pytest
python3.11 -m pip install -e .

#install
if ! pyproject-build; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#test
if ! pytest; then
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
