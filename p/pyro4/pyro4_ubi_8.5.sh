#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package	: Pyro4
# Version	: 4.81
# Source repo	: https://github.com/irmen/Pyro4
# Tested on	: ubi 8.5
# Language      : python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Adilhusain Shaikh <Adilhusain.Shaikh@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="Pyro4"
PACKAGE_VERSION=${1:-"4.81"}
PACKAGE_URL="https://github.com/irmen/Pyro4"
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

echo "Installing dependencies from system repos..."
dnf install -qy git gcc-c++ python38-devel make

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
# setup python virtual env
python3 -m venv ~/"$PACKAGE_NAME"
source ~/"$PACKAGE_NAME"/bin/activate
pip install wheel
pip install -r ./requirements.txt
pip install -r ./test_requirements.txt
if ! make install; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! make test; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
