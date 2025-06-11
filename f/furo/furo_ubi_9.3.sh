#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : furo
# Version          : 2024.08.06
# Source repo      : https://github.com/pradyunsg/furo
# Tested on        : UBI 9.5
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Haritha Nagothu <haritha.nagothu2@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_NAME=furo
PACKAGE_VERSION=${1:-"2024.08.06"}
PACKAGE_URL=https://github.com/pradyunsg/furo

# Install dependencies
yum install -y python3.12-devel git python3.12-pip gcc-toolset-13 make
source /opt/rh/gcc-toolset-13/enable
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH

git clone https://github.com/nodakai/tree-command.git
cd tree-command
make
cp tree /usr/local/bin/
cd ..

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc   
nvm --version
nvm install 18

# NODE_VERSION=18.20.2
# curl -O https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION.tar.gz
# tar -xzf node-v$NODE_VERSION.tar.gz
# cd node-v$NODE_VERSION
# ./configure
# make -j$(nproc)
# make install
# cd .. 

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION 

python3.12 -m pip install tomli pytest httpx  wheel sphinx-theme-builder

if ! python3.12 -m pip install . --no-build-isolation ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! python3.12 -m pytest ; then
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
