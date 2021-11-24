# ---------------------------------------------------------------------
#
# Package       : Font-Awesome
# Version       : 5.1.0
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

#!/bin/bash

set -ex

#Variables
REPO=https://github.com/FortAwesome/Font-Awesome.git
VERSION=5.1.0
NAME=Font-Awesome

#Dependencies
yum install -y git
dnf module install -y nodejs:12

#Clone
cd /opt
git clone $REPO
cd $NAME
git checkout $VERSION

#Node install and build
cd advanced-options/use-with-node-js/fontawesome
for dir in ../*/ ; do
	cd $dir
	npm install
	npm build
done

#Conclude
set +ex
echo "Complete. No tests to run."
