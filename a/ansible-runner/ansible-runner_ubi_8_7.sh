#!/bin/bash
# ---------------------------------------------------------------------
#
# Package       : ansible-runner
# Version       : 2.3.3
# Source repo   : https://github.com/ansible/ansible-runner
# Tested on     : UBI 8.7
# Language      : Python,shell script
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

PACKAGE_NAME=ansible-runner
PACKAGE_URL=https://github.com/ansible/ansible-runner
PACKAGE_VERSION=${1:-2.3.3}
PACKAGE_MVN=${PACKAGE_MVN:-"3.8.8"}

yum install java-17-openjdk-devel openssl-devel git wget tar python39-devel.ppc64le gcc rust cargo man gcc-c++ cmake.ppc64le -y

wget https://dlcdn.apache.org/maven/maven-3/$PACKAGE_MVN/binaries/apache-maven-$PACKAGE_MVN-bin.tar.gz
ls /usr/local
tar -C /usr/local/ -xzf apache-maven-$PACKAGE_MVN-bin.tar.gz
mv /usr/local/apache-maven-$PACKAGE_MVN /usr/local/maven
ls /usr/local
rm apache-maven-$PACKAGE_MVN-bin.tar.gz
export M2_HOME=/usr/local/maven
# update the path env. variable
export PATH=$PATH:$M2_HOME/bin
pip3 install build 
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
#Checkout devel branch as it is having latest fix,features
git checkout $PACKAGE_VERSION

export JDK_HOME=/usr/lib/jvm/java-17-openjdk
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk

pip3 install -r test/requirements.txt ansible
pip3 install .

# update the path env. variable for ansible installation
export ANSIBLE_HOME="/usr/local/bin"
export PATH=$PATH:$ANSIBLE_HOME

if ! python3 -m build; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
fi

ln -s /usr/bin/python3 /usr/bin/python

#skipping podman and docker as podman can/t be installed inside docker container also timeout failures as it required to increase time runtime.
if ! pytest -k "not podman and not test_keepalive_setting" -v; then
    echo "------------------$PACKAGE_NAME:test_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 2
fi

