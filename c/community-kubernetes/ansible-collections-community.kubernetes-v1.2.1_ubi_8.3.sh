#----------------------------------------------------------------------------------------------------
#
# Package       : community.kubernetes
# Version       : main, v1.2.1
# Source repo   : https://github.com/ansible-collections/community.kubernetes
# Tested on     : UBI 8.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Jotirling Swami <Jotirling.Swami1@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------------------------------

#!/bin/bash

set -ex

#Variables
REPO=https://github.com/ansible-collections/community.kubernetes.git
PACKAGE_VERSION=1.2.1

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is main, not all versions are supported."

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#install dependencies
yum update -y
yum install -y git wget unzip python3 python38 python38-pip python38-devel python3-devel make gcc gcc-c++ libffi-devel.ppc64le libffi.ppc64le cargo.ppc64le openssl.ppc64le openssl-devel.ppc64le
ln -s /usr/bin/python3.8 /usr/bin/python
pip3 install tox wheel setuptools_rust
pip3 install cryptography ansible==4.9.0 openshift molecule yamllint flake8

#clone the repo
cd /opt && git clone $REPO
cd community.kubernetes/
if [[ "$PACKAGE_VERSION" = "main" ]]
then
	git checkout main
else
	git checkout $PACKAGE_VERSION
fi

# build
make build
make install

# test
# make test-sanity
# make test-molecule