#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : python-memcached
# Version       : 1.62
# Source repo   : https://github.com/linsomniac/python-memcached
# Tested on		  : UBI 9.5
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	  : Haritha Nagothu <haritha.nagothu2@ibm.com>
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

#Variables
PACKAGE_NAME=python_memcached
PACKAGE_VERSION="${1:-1.62}"
PACKAGE_URL=https://github.com/linsomniac/python-memcached
PACKAGE_DIR=python-memcached

#Install dependencies.
yum install -y python-devel git python-pip  memcached gcc-toolset-13 
source /opt/rh/gcc-toolset-13/enable
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH


#clone the repo.
git clone $PACKAGE_URL
cd $PACKAGE_DIR/
git checkout $PACKAGE_VERSION

# The community has not updated the version string in memcache.py for the latest release.
# As a result, setup.py picks up an older version. To ensure the correct version is used during packaging,
# we update the __version__ variable in memcache.py to match PACKAGE_VERSION.

sed -i "s/^__version__ *= *[\"'].*[\"']/__version__ = \"$PACKAGE_VERSION\"/" memcache.py


pip install -r requirements.txt
pip install -r test-requirements.txt
pip install pytest setuptools


if ! pip install .; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Start memcached (default port 11211)
memcached -d -m 64 -p 11211 -u root

if ! pytest tests/ ; then
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
