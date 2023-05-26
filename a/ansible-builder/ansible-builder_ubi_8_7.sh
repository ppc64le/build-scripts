#!/bin/bash
# ---------------------------------------------------------------------
#
# Package       : ansible-builder
# Version       : 3.0.0
# Source repo   : https://github.com/ansible/ansible-builder
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

PACKAGE_NAME=ansible-builder
PACKAGE_URL=https://github.com/ansible/ansible-builder
PACKAGE_VERSION=${1:-3.0.0}

yum install java-17-openjdk-devel openssl-devel git wget tar python39-devel.ppc64le gcc rust cargo  gcc-c++ cmake.ppc64le -y

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME | Removed existing package if any"
fi

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 
fi

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

export JDK_HOME=/usr/lib/jvm/java-17-openjdk
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk

pip3 install tox build
export ANSIBLE_HOME="/usr/local/bin"
export PATH=$PATH:$ANSIBLE_HOME
#Set Tox environment
tox --notest

if ! python3 -m build; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
fi

if ! tox -- --run-destructive; then
    echo "------------------$PACKAGE_NAME:test_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 2
fi
