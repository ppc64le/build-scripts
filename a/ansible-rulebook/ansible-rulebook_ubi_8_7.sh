#!/bin/bash
# ---------------------------------------------------------------------
#
# Package       : ansible-rulebook
# Version       : v0.11.0
# Source repo   : https://github.com/ansible/ansible-rulebook.git
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

PACKAGE_NAME=ansible-rulebook
PACKAGE_URL=https://github.com/ansible/ansible-rulebook.git
PACKAGE_VERSION=${1:-v0.11.0}
PACKAGE_MVN=${PACKAGE_MVN:-"3.8.8"}

yum install java-17-openjdk-devel openssl-devel git wget tar python39-devel.ppc64le gcc rust cargo  gcc-c++ cmake.ppc64le -y

wget https://dlcdn.apache.org/maven/maven-3/$PACKAGE_MVN/binaries/apache-maven-$PACKAGE_MVN-bin.tar.gz
tar -xzvf apache-maven-$PACKAGE_MVN-bin.tar.gz -C /opt/
ln -sf /opt/apache-maven-$PACKAGE_MVN/bin/mvn /usr/local/bin/mvn
rm -f apache-maven-$PACKAGE_MVN-bin.tar.gz

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME | Removed existing package if any"
fi

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 0
fi

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

export JDK_HOME=/usr/lib/jvm/java-17-openjdk
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk

pip3 install -r requirements_test.txt
pip3 install .
ansible-galaxy collection install git+https://github.com/ansible/event-driven-ansible
pip3 install pyparsing jsonschema websockets drools-jpy build

if ! python3 -m build; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
fi

export EDA_E2E_CMD_TIMEOUT=120
export EDA_E2E_DEFAULT_EVENT_DELAY=2
if ! pytest -v -n auto; then
    echo "------------------$PACKAGE_NAME:test_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 2
fi
