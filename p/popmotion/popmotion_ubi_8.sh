# -----------------------------------------------------------------------------
#
# Package       : popmotion
# Version       : v8.7.1
# Source repo   : https://github.com/Popmotion/popmotion
# Tested on     : RHEL 8.3
# Script License: Apache License, Version 2 or later
# Maintainer    : sachin.kakatkar@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=popmotion
PACKAGE_VERSION=master
PACKAGE_URL=https://github.com/Popmotion/popmotion.git

docker run -it --name popmotion-04 registry.access.redhat.com/ubi8/ubi bash
dnf install git -y
dnf install npm -y
mkdir test
cd test
git clone https://github.com/Popmotion/popmotion.git
cd popmotion
git checkout v8.7.1
npm install --global yarn
yarn
yarn bootstrap
cd packages/popmotion
yarn test

