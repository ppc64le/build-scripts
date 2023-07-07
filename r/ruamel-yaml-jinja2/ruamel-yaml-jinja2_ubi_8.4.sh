#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : ruamel-yaml-jinja2
# Version       : 0.2.7
# Source repo   : http://hg.code.sf.net/p/ruamel-yaml-jinja2/code
# Tested on	: UBI 8.4
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Apurva Agrawal <Apurva.Agrawal3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=ruamel-yaml-jinja2
PACKAGE_VERSION=${1:-0.2.7}
PACKAGE_URL=http://hg.code.sf.net/p/ruamel-yaml-jinja2/code

yum -y update && yum install -y python3 python3-devel gcc gcc-c++ make redhat-rpm-config
python3 -m pip install Mercurial

HOME_DIR=`pwd`
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

if ! hg clone $PACKAGE_URL $PACKAGE_NAME; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
                echo "$PACKAGE_URL $PACKAGE_NAME"
                echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail |  Clone_Fails"
        exit 0
fi

cd $HOME_DIR/$PACKAGE_NAME
hg checkout $PACKAGE_VERSION

if ! python3 -m pip install .; then
    echo "------------------$PACKAGE_NAME:install_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail |  Install_Fails"
        exit 0
fi

cd $HOME_DIR/$PACKAGE_NAME
if ! python3 _test/test_jinja2.py; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo  "$PACKAGE_URL $PACKAGE_NAME "
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail |  Install_success_but_test_Fails"
        exit 0
else
        echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
        echo  "$PACKAGE_URL $PACKAGE_NAME "
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE  | Pass |  Both_Install_and_Test_Success"
        exit 0
fi
