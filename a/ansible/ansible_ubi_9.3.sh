#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package           : ansible
# Version           : v2.18.6
# Source repo       : https://github.com/ansible/ansible.git
# Tested on         : UBI:9.3
# Language          : Python
# Travis-Check      : True
# Script License    : Apache License, Version 2 or later
# Maintainer        : Bharti Somra(Bharti.Somra@ibm.com)
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
# ----------------------------------------------------------------------------
#

PACKAGE_NAME=ansible
PACKAGE_URL=https://github.com/ansible/ansible.git
PACKAGE_VERSION=${1:-v2.18.6}

dnf update -y && dnf upgrade -y

# Installing dependencies
dnf install -y git python3.11 python3.11-pip python3.11-devel gcc rust cargo openssl-devel diffutils libyaml-devel openssh-server openssh-clients

## SSH connection to localhost is required for integration testing
## Follow below steps if ssh service is not available
#for keytype in rsa ecdsa ed25519; do
#    if [ ! -f "/etc/ssh/ssh_host_${keytype}_key" ]; then
#        ssh-keygen -A # Create host keys (if missing)
#    fi
#done

#mkdir -p ~/.ssh
#chmod 700 ~/.ssh
#ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa 
#cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
#chmod 600 ~/.ssh/authorized_keys

## Start sshd manually
#/usr/sbin/sshd -D &
#ssh-keyscan -H localhost >> ~/.ssh/known_hosts

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#To create virtual environment
python3.11 -m venv .venv
source .venv/bin/activate

pip install --upgrade pip

# Force install PyYAML to trigger C extension build
pip install --force-reinstall --no-binary=:all: PyYAML

export ANSIBLE_LIBRARY=./test/integration/targets/ansible-doc/library

#Installing Package Dependencies
pip install .
pip install build pytest pytest-xdist pytest-mock

#Building Package
if ! python3 -m build ; then
    echo "------------------$PACKAGE_NAME:Build_Failure---------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Failure"
    exit 1
fi

#Installing requirements for unit testing
pip install -r test/units/requirements.txt

#Unit and Sanity Testing
if ! ./bin/ansible-test units --python 3.11 && ./bin/ansible-test sanity --python 3.11 ; then
    echo "------------------$PACKAGE_NAME:Unit_and_Sanity_Test_Failure---------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Test_Failure"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Build & Unit_and_Sanity_Test Passed Successfully---------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Passed | Build_&_Test_Successfull"
    exit 0
fi

##Running integration tests
#./bin/ansible-test integration --python 3.11
##Dependency images for integration tests
##quay.io/ansible/nios-test-container              5.0.0
##quay.io/ansible/ansible-test-utility-container   3.1.0
##quay.io/ansible/http-test-container              3.2.0
##quay.io/ansible/cloudstack-test-container        1.7.0    
##quay.io/pulp/galaxy                              4.7.1
##quay.io/ansible/acme-test-container              2.1.0
