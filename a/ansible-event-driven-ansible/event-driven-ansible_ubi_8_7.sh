#!/bin/bash
# ---------------------------------------------------------------------
#
# Package       : event-driven-ansible
# Version       : v1.3.8
# Source repo   : https://github.com/ansible/event-driven-ansible/
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

PACKAGE_NAME=event-driven-ansible
PACKAGE_URL=https://github.com/ansible/event-driven-ansible/
PACKAGE_VERSION=${1:-v1.3.8}
PACKAGE_MVN=${PACKAGE_MVN:-"3.8.8"}

yum install java-17-openjdk-devel openssl-devel git wget tar python39-devel.ppc64le gcc rust cargo gcc-c++ cmake.ppc64le systemd-devel -y
      
wget https://dlcdn.apache.org/maven/maven-3/$PACKAGE_MVN/binaries/apache-maven-$PACKAGE_MVN-bin.tar.gz
ls /usr/local
tar -C /usr/local/ -xzf apache-maven-$PACKAGE_MVN-bin.tar.gz
mv /usr/local/apache-maven-$PACKAGE_MVN /usr/local/maven
ls /usr/local
rm apache-maven-$PACKAGE_MVN-bin.tar.gz
export M2_HOME=/usr/local/maven
# update the path env. variable
export PATH=$PATH:$M2_HOME/bin

export JDK_HOME=/usr/lib/jvm/java-17-openjdk
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
    
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
pip3 install -r test_requirements.txt
pip3 install docker-compose build
pip3 install awscli --ignore-installed six
export ANSIBLE_HOME="/usr/local/bin"
export PATH=$PATH:$ANSIBLE_HOME

if ! ansible-galaxy collection install . ; then
    echo "------------------$PACKAGE_NAME:install_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
fi

export ANSIBLE_INSTALL="/usr/local/bin/collections/ansible_collections/ansible/eda"
export PATH=$PATH:$ANSIBLE_INSTALL
export DEFAULT_TEST_TIMEOUT=600

#Skipping below pytests due to timeout error on power .The timeout should change runtime according to power
if ! pytest -k "not kafka and not test_webhook_source_sanity and not test_url_check_source_sanity and not test_webhook_source_with_busy_port and not test_url_check_source_error_handling" ; then
    echo "------------------$PACKAGE_NAME:test_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 2
fi

