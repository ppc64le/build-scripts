#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: chownr
# Version	: v1.1.3
# Source repo	: https://github.com/isaacs/chownr
# Tested on	: UBI 8.4
# Language      : Node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Sapana Khemkar {Sapana.Khemkar@ibm.com}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=chownr
PACKAGE_VERSION=${1:-v1.1.3}
PACKAGE_URL=https://github.com/isaacs/chownr

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "       PACKAGE_VERSION is an optional paramater whose default value is v0.5.1"

# install tools and dependent packages
yum -y update
yum -y install git wget gcc-c++ make python2 curl

NODE_VERSION=v12.22.4
#installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install $NODE_VERSION

# clone, build and test specified version
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

npm install

# npm test failed with below which in parity with x86
# not ok gid should be undefined
# 44 passing (3s)
#  52 failing
#
#-----------|----------|----------|----------|----------|-------------------|
#File       |  % Stmts | % Branch |  % Funcs |  % Lines | Uncovered Line #s |
#-----------|----------|----------|----------|----------|-------------------|
#All files  |       70 |    45.95 |    83.33 |    67.86 |                   |
# chownr.js |       70 |    45.95 |    83.33 |    67.86 |... 05,113,114,115 |
#-----------|----------|----------|----------|----------|-------------------|
npm test

exit 0

