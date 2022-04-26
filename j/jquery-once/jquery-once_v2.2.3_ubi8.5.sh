#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package: jquery-once
# Version: 2.2.3
# Source repo: https://github.com/RobLoach/jquery-once
# Tested on: RHEL v8.5
# Language: PHP
# Travis-Check: True
# Script License: Apache License, Version 2 or later
# Maintainer: Prashant Khoje <prashant.khoje@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex
PACKAGE_NAME=jquery-once
PACKAGE_VERSION=${1:-2.2.3}
PACKAGE_URL="https://github.com/RobLoach/jquery-once"

dnf install -y git wget
DISTRO=linux-ppc64le

cd $HOME
# Install nodejs
NODE_VERSION=v14.19.1
wget https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-$DISTRO.tar.gz
tar -xzf node-$NODE_VERSION-$DISTRO.tar.gz
export PATH=$HOME/node-$NODE_VERSION-$DISTRO/bin:$PATH
rm -f node-$NODE_VERSION-$DISTRO.tar.gz

node --version

cd $HOME
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
npm install
npm run build
echo "Tests fail in parity with x86-64."
npm test

# Expected test log
# > jquery-once@2.2.3 test
# > mocha test/test.js --env node
#
#
#
#  jQuery Once
#    ✓ should require ID to be a string
#    ✓ properly executes .once("test2")
#    ✓ is called only once with an ID
#     ✓ is called only once without an ID
#     ✓ retrieves empty once data correctly
#    ✓ calls removeOnce() correctly
#    ✓ calls findOnce() correctly
#
# 
#   7 passing (701ms)
# 
# 
# > jquery-once@2.2.3 posttest
# > xo --space=2 --no-esnext jquery.once.js test
#
#
#  test/test.js:1:1
#   ✖    1:1   Unexpected var, use let or const instead.                                       no-var
#   ✖    1:14  Do not use "require".                                                           unicorn/prefer-module
#   ✖    2:1   Unexpected var, use let or const instead.                                       no-var
#   ✖    2:13  Do not use "require".                                                           unicorn/prefer-module
#   ✖    8:25  Unexpected function expression.                                                 prefer-arrow-callback
#   ✖   12:3   Unexpected var, use let or const instead.                                       no-var
#   ✖   18:28  Missing trailing comma.                                                         comma-dangle
#   ✖   24:10  Unexpected function expression.                                                 prefer-arrow-callback
#   ✖   25:9   Do not use "require".                                                           unicorn/prefer-module
#   ✖   26:14  Do not use "require".                                                           unicorn/prefer-module
#   ✖   32:14  Unexpected function expression.                                                 prefer-arrow-callback
#   ✖   38:42  Unexpected function expression.                                                 prefer-arrow-callback
#   ✖   40:19  Unexpected function expression.                                                 prefer-arrow-callback
#   ✖   41:22  Unexpected function expression.                                                 prefer-arrow-callback
#   ✖   47:42  Unexpected function expression.                                                 prefer-arrow-callback
#   ✖   55:5   Unexpected var, use let or const instead.                                       no-var
#   ✖   59:40  Unexpected function expression.                                                 prefer-arrow-callback
#   ✖   64:5   Unexpected var, use let or const instead.                                       no-var
#   ✖   70:10  Unexpected var, use let or const instead.                                       no-var
#   ✖   75:5   Unexpected var, use let or const instead.                                       no-var
#   ✖   79:43  Unexpected function expression.                                                 prefer-arrow-callback
#   ✖   84:5   Unexpected var, use let or const instead.                                       no-var
#   ✖   89:10  Unexpected var, use let or const instead.                                       no-var
#   ✖   94:5   Unexpected var, use let or const instead.                                       no-var
#   ✖   98:45  Unexpected function expression.                                                 prefer-arrow-callback
#   ✖  100:5   Unexpected var, use let or const instead.                                       no-var
#   ✖  111:38  Unexpected function expression.                                                 prefer-arrow-callback
#   ✖  116:5   Unexpected var, use let or const instead.                                       no-var
#   ✖  125:36  Unexpected function expression.                                                 prefer-arrow-callback
#
#   jquery.once.js:18:3
#   ✖   18:3   Do not use "use strict" directive.                                              unicorn/prefer-module
#   ✖   20:14  Do not use "exports".                                                           unicorn/prefer-module
#   ✖   20:45  Do not use "exports".                                                           unicorn/prefer-module
#   ✖   22:13  Do not use "require".                                                           unicorn/prefer-module
#   ✖   32:4   Unexpected function expression.                                                 prefer-arrow-callback
#   ✖   33:3   Do not use "use strict" directive.                                              unicorn/prefer-module
#   ✖   46:3   Unexpected var, use let or const instead.                                       no-var
#   ✖   47:5   Prefer default parameters over reassignment.                                    unicorn/prefer-default-parameters
#   ✖   95:5   Unexpected var, use let or const instead.                                       no-var
#   ✖  171:5   Unexpected var, use let or const instead.                                       no-var
#
#   test/index.js:4:1
#   ✖    4:1   Unexpected var, use let or const instead.                                       no-var
#   ✖    4:12  Do not use "require".                                                           unicorn/prefer-module
#   ✖    5:1   Unexpected var, use let or const instead.                                       no-var
#   ✖    5:13  Do not use "require".                                                           unicorn/prefer-module
#   ✖    8:1   Unexpected var, use let or const instead.                                       no-var
#   ✖   11:25  Do not use "__dirname".                                                         unicorn/prefer-module
#   ✖   14:11  Unexpected function expression.                                                 prefer-arrow-callback
#   ✖   15:3   Unexpected use of the global variable process. Use require("process") instead.  node/prefer-global/process
#   ✖   15:22  Unexpected function expression.                                                 prefer-arrow-callback
# 
#   48 errors

