#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : highlight.js
# Version          : 10.7.2,11.5.1
# Source repo      : https://github.com/highlightjs/highlight.js
# Tested on        : UBI 8.5
# Language         : Node
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vathsala . <vaths367@in.ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=highlight.js
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-10.7.2}
PACKAGE_URL=https://github.com/highlightjs/highlight.js
yum install -y yum-utils git jq
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc

nvm install "$NODE_VERSION"

npm install -g npm@8.3.0

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

npm install
npm run build
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done build ..."
else
  echo  "Failed build......"
  exit
fi

npm run test
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done Test ......"
else
  echo  "Failed Test ......"
fi
