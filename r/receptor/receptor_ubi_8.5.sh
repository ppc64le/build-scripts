#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: receptor
# Version	: devel
# Source repo	: https://github.com/ansible/receptor
# Tested on	: UBI: 8.5
# Language      : GO
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer	: Sunidhi Gaonkar<Sunidhi.Gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=receptor
PACKAGE_VERSION=${1:-devel}
PACKAGE_URL=https://github.com/ansible/receptor

#Install dependencies
sudo yum -y install git curl make python39-devel python39-pip 
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Build and test
pip3 install build
#sed -i '127s/podman/docker/' Makefile  
make container REPO=receptor TAG=devel
docker run --rm receptor:devel receptor --version

# ****Note****
# Travis check is set to false as the script needs to be run on VM.
# Container command can be docker or podman.

