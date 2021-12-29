# ----------------------------------------------------------------------------
#
# Package       : operator-sdk-ansible-util
# Version       : v0.2.0
# Source repo   : https://github.com/operator-framework/operator-sdk-ansible-util.git
# Tested on     : UBI: 8.3
# Script License: Apache License 2.0
# Maintainer's  : Balavva Mirji <Balavva.Mirji@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
# Command to create container: docker run --network host -it --name container_name -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker registry.access.redhat.com/ubi8/ubi:8.3
#!/bin/bash

# Variables
REPO=https://github.com/operator-framework/operator-sdk-ansible-util.git
PACKAGE_VERSION=v0.2.0

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is v0.2.0"

# Install tools and dependent packages
yum update -y
yum install -y git wget unzip python3 python38 python38-pip python38-devel python3-devel make gcc gcc-c++ libffi-devel.ppc64le libffi.ppc64le cargo.ppc64le openssl.ppc64le openssl-devel.ppc64le
ln -s /usr/bin/python3.8 /usr/bin/python

# Install ansible and openshift dependencies
python3.8 -m pip install cryptography ansible openshift  molecule yamllint flake8 pycodestyle pylint

# Cloning Repo
git clone $REPO
cd /operator-sdk-ansible-util/
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