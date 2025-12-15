#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : entrypoints
# Version       : 0.4
# Source repo   : https://github.com/takluyver/entrypoints
# Tested on     : UBI: 8.7
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

# Variables
export PACKAGE_VERSION=${1:-"0.4"}
export PACKAGE_NAME=entrypoints
export PACKAGE_URL=https://github.com/takluyver/entrypoints


# Install dependencies
yum install -y python39 git gcc-c++ python39-devel.ppc64le python3-setuptools
pip3 install --upgrade setuptools virtualenv mock ipython_genutils pytest traitlets flit

dnf install -qy http://mirror.nodesdirect.com/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-6.el8.noarch.rpm
dnf install -qy http://mirror.nodesdirect.com/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-stream-repos-8-6.el8.noarch.rpm
dnf config-manager --enable powertools
dnf install -qy epel-release

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
virtualenv -p python3 --system-site-packages env2 
/bin/bash -c "source env2/bin/activate"
PATH=$PATH:/usr/local/bin/
pip3 install setuptools wheel
pip3 install configparser
pip3 install -U entrypoints


# Install
if !(pip3 install . pytest) ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Run test cases
if !(pytest); then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi