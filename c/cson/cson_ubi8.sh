#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package               : cson
# Version               : 7.0.0,6.9.0
# Source repo           : https://github.com/bevry/cson
# Tested on             : UBI 8
# Language              : Node
# Travis-Check          : True
# Script License        : Apache License, Version 2 or later
# Maintainer            : Swati Singhal<swati.singhal@ibm.com>,Saraswati Patra <saraswati.patra@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_VERSION=7.0.0

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "       PACKAGE_VERSION is an optional paramater whose default value is 7.0.0"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

# install tools and dependent packages
yum -y install git wget gcc-c++ make python2 curl

NODE_VERSION=v12.22.4
#installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install $NODE_VERSION

# clone, build and test specified version

git clone https://github.com/bevry/cson
cd cson
git checkout v$PACKAGE_VERSION
npm install && npm audit fix && npm audit fix --force
#1 test failing
npm test

#build is passed but test is in parity for both mentioned version

#internal/modules/cjs/loader.js:818
#  throw err;
#  ^

#Error: Cannot find module '/cson/edition-esnext/test.js'
#    at Function.Module._resolveFilename (internal/modules/cjs/loader.js:815:15)
#    at Function.Module._load (internal/modules/cjs/loader.js:667:27)
#    at Function.executeUserEntryPoint [as runMain] (internal/modules/run_main.js:60:12)
#    at internal/main/run_main_module.js:17:47 {
#  code: 'MODULE_NOT_FOUND',
#  requireStack: []
#}
#npm ERR! Test failed.  See above for more details.
