#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : py-spy
# Version          : v0.4.0
# Source repo      : https://github.com/benfred/py-spy.git
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Md. Shafi Hussain <Md.Shafi.Hussain@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=py-spy
PACKAGE_VERSION=${1:-v0.4.0}
PACKAGE_URL=https://github.com/benfred/py-spy.git
PACKAGE_DIR=py-make

CURRENT_DIR=${PWD}

yum install -y git gcc-toolset-13 python-devel python-pip

source /opt/rh/gcc-toolset-13/enable

#Install rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > sh.rustup.rs && \
sh ./sh.rustup.rs -y && export PATH=$PATH:$HOME/.cargo/bin && . "$HOME/.cargo/env"

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Build package
if ! pip install . ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi


#Test package
if ! cargo test --release ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
