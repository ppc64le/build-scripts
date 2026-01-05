#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : jupyter_core
# Version          : v5.8.1
# Source repo      : https://github.com/jupyter/jupyter_core.git
# Tested on        : UBI 9.3
# Language         : Python, javascript
# Ci-Check     : True
# Script License   : GNU General Public License v3.0
# Maintainer       : Anumala Rajesh <Anumala.Rajesh@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex 

PACKAGE_NAME=jupyter_core
PACKAGE_VERSION=${1:-v5.8.1}
PACKAGE_URL=https://github.com/jupyter/jupyter_core.git
CURRENT_DIR=$(pwd) 

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

# Install base dependencies
yum install -y wget git make python3.12 python3.12-pip python3.12-devel gcc-toolset-13 cmake

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH 
source /opt/rh/gcc-toolset-13/enable  

echo " -------------------------------------------- Installing Dependencies -------------------------------------------- "

yum install -y openssl openssl-devel 

python3.12 -m pip install -U pip 
python3.12 -m pip install hatch

echo " -------------------------------------------- Jupyter Core Cloning -------------------------------------------- " 

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

echo " -------------------------------------------- Jupyter Core Installing -------------------------------------------- " 

if ! python3.12 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

python3.12 -m pip install ".[test]"

if ! hatch run test:nowarn ; then
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