# ---------------------------------------------------------------------
#
# Package       : dc-js
# Version       : 4.2.7
# Source repo   : https://github.com/dc-js/dc.js.git
# Tested on     : UBI 8.3 (Docker)
# Script License: Apache License, Version 2 or later
# Maintainer    : Sumit Dubey <Sumit.Dubey2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------

#!/bin/sh

#Variables
REPO=https://github.com/dc-js/dc.js.git
PACKAGE_VERSION=4.2.7

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is 4.2.7"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#Install Dependencies
yum install -y nodejs git make gcc-c++ python2
dnf -y install \
	http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-linux-repos-8-3.el8.noarch.rpm \
	http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-3.el8.noarch.rpm
yum install -y firefox
npm install grunt --save-dev
npm install -g grunt-cli

#Clone the repo
cd /opt/
git clone $REPO
cd dc.js

#Checkout the required version
git checkout ${PACKAGE_VERSION}

#Build and test
npm install
grunt test --force

#Done
echo "/opt/dc.js/dist/dc.min.js"
echo "/opt/dc.js/dist/style/dc.min.css"
echo "Complete!"
