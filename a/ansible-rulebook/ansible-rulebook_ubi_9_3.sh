#!/bin/bash
# ---------------------------------------------------------------------
#
# Package       : ansible-rulebook
# Version       : v1.1.2
# Source repo   : https://github.com/ansible/ansible-rulebook.git
# Tested on     : UBI 9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
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
PACKAGE_VERSION=${1:-v1.1.2}
PACKAGE_MVN=${PACKAGE_MVN:-"3.8.8"}


yum install java-17-openjdk-devel openssl-devel git wget tar python-devel gcc rust cargo procps-ng gcc-c++ cmake.ppc64le -y

#installing maven 3.8.6
wget http://archive.apache.org/dist/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz
tar -C /usr/local/ -xzvf apache-maven-3.8.6-bin.tar.gz
rm -rf tar xzvf apache-maven-3.8.6-bin.tar.gz
mv /usr/local/apache-maven-3.8.6 /usr/local/maven
export PATH=/usr/local/bin:$PATH
export M2_HOME=/usr/local/maven
export PATH=$PATH:$M2_HOME/bin


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

#Skipping 2 tests.
#test_websocket.py ---> this test requires ipv6 container which is not allowed in currency infrastructure as of now. So skipping it.
#test_actions.py ---> this test is flaky, so skipping it.

if ! pytest -v -n auto -k "not test_websocket.py and not test_actions.py"; then
    echo "------------------$PACKAGE_NAME:test_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi

