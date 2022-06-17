#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package	: ruamel-yaml-jinja2-code
# Version	: 0.2.7
# Source repo	: http://hg.code.sf.net/p/ruamel-yaml-jinja2/code ruamel-yaml-jinja2-code
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

PACKAGE_NAME="ruamel-yaml-jinja2-code"
PACKAGE_VERSION=${1:-"0.2.7"}
PACKAGE_URL="http://hg.code.sf.net/p/ruamel-yaml-jinja2/code ruamel-yaml-jinja2-code"
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

echo "Adding centos stream repos..."
dnf install -qy http://mirrors.liquidweb.com/CentOS/8-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-6.el8.noarch.rpm \
    http://mirrors.liquidweb.com/CentOS/8-stream/BaseOS/ppc64le/os/Packages/centos-stream-repos-8-6.el8.noarch.rpm

echo "Installing dependencies from system repos..."
dnf install -qy mercurial gcc-c++ python39-devel python38-devel

hg clone $PACKAGE_URL
cd $PACKAGE_NAME
hg update $PACKAGE_VERSION
# setup python virtual env
python3 -m venv ~/"$PACKAGE_NAME"
source ~/"$PACKAGE_NAME"/bin/activate
pip install tox wheel
if ! pip install .; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! tox; then
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
