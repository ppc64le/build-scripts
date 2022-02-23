#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: docker-openldap
# Version	: master
# Source repo	: https://github.ibm.com/velox/openldap
# Tested on	: UBI 8.4
# Language      : Shell, Python
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer	: Vaibhav Bhadade <vaibhav.bhadade@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

OPENLDAP_VERSION=1.5.0
BASEIMAGE_VERSION=1.3.2
CFSSL_VERSION=1.5.0

ARCH=$(uname -m)
WORKSPACE_DIR=$(pwd)

echo "------------------------------------"
echo "WORKSPACE_DIR : $WORKSPACE_DIR"
echo "contents of $WORKSPACE_DIR"
ls -la
echo "------------------------------------"

rm -rf cfssl docker-light-baseimage docker-openldap

# Install docker if not found
if ! [ $(command -v docker) ]; then
	yum install -y docker
fi

# Install git if not found
if ! [ $(command -v git) ]; then
	yum install -y git
fi

# Install make if not found
if ! [ $(command -v make) ]; then
	yum install -y make
fi

echo `ls`
git clone https://github.com/osixia/docker-light-baseimage && cd docker-light-baseimage

git checkout v$BASEIMAGE_VERSION
echo `pwd`
echo `ls /`

git apply $WORKSPACE_DIR/cfssl_ppc64le.patch

make build

cd $WORKSPACE_DIR
git clone https://github.com/osixia/docker-openldap.git
cd docker-openldap
sed -i -e "/PQCHECKER/Id" image/Dockerfile;
make
docker tag osixia/openldap:"${OPENLDAP_VERSION}" osixia/openldap:latest

