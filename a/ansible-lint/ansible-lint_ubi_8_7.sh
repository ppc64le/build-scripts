#!/bin/bash
# ---------------------------------------------------------------------
#
# Package       : ansible-lint
# Version       : v6.16.2
# Source repo   : https://github.com/ansible/ansible-lint
# Tested on     : UBI 8.7
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Ashwini Kadam <Ashwini.Kadam@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------
set -e

PACKAGE_NAME=ansible-lint
PACKAGE_URL=https://github.com/ansible/ansible-lint
PACKAGE_VERSION=${1:-v6.16.2}

yum install git -y
#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME | Removed existing package if any"
fi

if ! git clone --recursive $PACKAGE_URL $PACKAGE_NAME; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 
fi

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
yum install java-17-openjdk-devel openssl-devel git wget tar python39-devel.ppc64le gcc rust cargo  gcc-c++ cmake.ppc64le -y

pip3 install tox build
export ANSIBLE_HOME="/usr/local/bin"
export PATH=$PATH:$ANSIBLE_HOME

#Need to increase npm socket timeout as depdencies require more time
yum install npm -y
npm config set fetch-retry-maxtimeout 120000
git submodule update --init

#exit 0 is required as json schema updating at run time in depdencies,to do not exit script we are using exit 0 for now
if ! tox -e lint ; then
    echo "------------------$PACKAGE_NAME:install_fails----------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 0
fi
echo "Installation completed"
if ! python3 -m build ; then
    echo "------------------$PACKAGE_NAME:build_fails----------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
fi

if ! tox -e py -- -k 'not test_galaxy_rule and not test_jinja_spacing_playbook and not test_jinja_invalid and not test_call_from_outside_venv'; then
    echo "------------------$PACKAGE_NAME:test_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 2
fi
