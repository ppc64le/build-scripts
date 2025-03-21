#!/bin/bash -e
# ---------------------------------------------------------------------
#
# Package       : event-driven-ansible
# Version       : v2.6.0
# Source repo   : https://github.com/ansible/event-driven-ansible/
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Ashwini Kadam <Ashwini.Kadam@ibm.com>,Neha Avhad <Neha.Avhad1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------

PACKAGE_NAME=event-driven-ansible
PACKAGE_URL=https://github.com/ansible/event-driven-ansible/
PACKAGE_VERSION=${1:-v2.6.0}

yum install java-17-openjdk java-17-openjdk-devel java-17-openjdk-headless openssl-devel sudo git wget tar python3-devel python3-pip gcc gcc-c++ cmake.ppc64le systemd-devel zlib-devel krb5-devel rust cargo maven -y
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-17.0.14.0.7-2.el9.ppc64le
export PATH=$PATH:$JAVA_HOME/bin:$HOME/.cargo/bin:$PATH

mkdir -p ansible_collections/ansible
git clone $PACKAGE_URL
mv event-driven-ansible ansible_collections/ansible/eda

cd ansible_collections/ansible/eda
git checkout $PACKAGE_VERSION

# Update tox.ini to add JAVA_HOME
sed -i '/passenv =/ i\    JAVA_HOME=/usr/lib/jvm/java-17-openjdk-17.0.14.0.7-2.el9.ppc64le' tox.ini
# To assume no changes in files/folders
git update-index --assume-unchanged tox.ini
git update-index --assume-unchanged ansible_collections/
git update-index --assume-unchanged event-driven-ansible/

sudo dnf remove -y python3-chardet
python3 -m pip install --upgrade pip setuptools wheel tox
python3 -m pip install -r requirements.txt

if ! python3 -m pip install -r requirements.txt ; then
     echo "------------------$PACKAGE_NAME:Build_fails---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails_"
     exit 1
fi

if ! tox -e py39-unit ; then
      echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_and_Test_fails"
      exit 2
else
      echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
      exit 0
fi
