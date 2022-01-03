# -----------------------------------------------------------------------------
#
# Package       : remarkable
# Version       : v2.0.1
# Source repo   : https://github.com/jonschlinkert/remarkable.git
# Tested on     : UBI 8
# Script License: Apache License, Version 2 or later
# Maintainer    : Raju.Sah@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
yum update -y
yum -y install git npm
VERSION=${1:-v2.0.1}

#clone the repo.
git clone  https://github.com/jonschlinkert/remarkable.git
npm install remarkable --save
npm install -g yarn
cd remarkable/
git checkout $VERSION

#build  and test the package
yarn install
yarn test:ci
yarn lint
