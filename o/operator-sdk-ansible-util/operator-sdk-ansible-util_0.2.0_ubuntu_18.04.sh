#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package         : operator-sdk-ansible-util
# Version         : v0.2.0
# Source repo     : https://github.com/operator-framework/operator-sdk-ansible-util.git
# Tested on       : Ubuntu 18.04 (docker)
# Language        : Python
# Travis-Check    : True
# Script License  : Apache License 2.0
# Maintainer's    : Sumit Dubey <sumit.dubey2@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
# Command to create container: docker run --network host -it --name container_name -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker docker.io/ppc64le/ubuntu:18.04

# Variables
PACKAGE_NAME=operator-sdk-ansible-util
PACKAGE_URL=https://github.com/operator-framework/operator-sdk-ansible-util.git
PACKAGE_VERSION=${1:-v0.2.0} 

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is v0.2.0"

# Install tools and dependent packages
apt-get update -y
apt-get install -y git wget unzip python3.8 python3.8-dev python3.8-distutils build-essential libffi-dev cargo openssl libssl-dev curl
ln -s /usr/bin/python3.8 /usr/bin/python
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3.8 get-pip.py

# Install ansible and openshift dependencies
python3.8 -m pip install cryptography ansible openshift molecule yamllint flake8 pycodestyle pylint


# Cloning Repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout ${PACKAGE_VERSION}

# Installation from galaxy
ansible-galaxy collection install operator_sdk.util

# Build the collection
make build

<<Tests_execution
Excluding both sanity and molecule tests
make test-sanity
sanity tests are not applicable for x86 as well confirmed with CI logs for x86
make test-molecule
To execute molecule tests we need openshift cluster, moreover CI is failing for x86.
Tests_execution