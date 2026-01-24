# ----------------------------------------------------------------------------------------------------------------------
#
# Package       : popper.js (popper-core)
# Version       : 1.16.1
# Source repo   : https://github.com/chtd/psycopg2cffi.git
# Tested on     : UBI 8.3 (Docker)
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Mukati <Amit.Mukati3@ibm.com>
# Instructions  : 1. mount to get pre-built binary:
#                 mount -t nfs 129.40.81.15:/nfsrepos /nfsrepos
#                 2. Run docker container as:
#                 docker run -it -v /nfsrepos/chromium:/chromium registry.access.redhat.com/ubi8/ubi /bin/bash
#                 3. Run this script
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------------------------------------------------

#!/bin/bash

set -ex

#Variables
REPO=https://github.com/popperjs/popper-core.git
PACKAGE_VERSION=1.16.1

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is master, not all versions are supported."

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#install dependencies
yum install git sed unzip procps java-1.8.0-openjdk java-1.8.0-openjdk-devel -y
dnf module install -y nodejs:14
curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo
rpm --import https://dl.yarnpkg.com/rpm/pubkey.gpg
dnf install -y yarn

#clone the repo
cd /opt && git clone $REPO
cd popper-core/
if [[ "$PACKAGE_VERSION" = "master" ]]
then
        git checkout master
else
        git checkout v$PACKAGE_VERSION
fi

#install node dependencies
yarn install
yarn add closure-compiler -W

#build
yarn build

#conclude
echo "Build Complete. Uncomment the following lines to run tests, they may take a while to complete."

#install Chrome dependencies
dnf -y install \
http://vault.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-linux-repos-8-3.el8.noarch.rpm \
http://vault.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-3.el8.noarch.rpm
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Linux-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Linux-*
yum install -y firefox libXScrnSaver libdrm mesa-libgbm alsa-lib libxshmfence
cd /opt
unzip chromium_84_0_4118_0.zip
export CHROME_BIN=/opt/chromium_84_0_4118_0/chrome
chmod 777 $CHROME_BIN
cd /opt/popper-core/packages/popper/tests
yarn test --scope=popper.js
echo "Tests Complete!"
