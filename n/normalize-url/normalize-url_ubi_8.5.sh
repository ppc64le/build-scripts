#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : normalize-url
# Version          : 6.1.0
# Source repo      : https://github.com/sindresorhus/normalize-url
# Tested on        : RHEL 8.5,UBI 8.5
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

PACKAGE_NAME=normalize-url
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-v6.1.0}
PACKAGE_URL=https://github.com/sindresorhus/normalize-url
yum install -y git jq

curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Install latest version of node and npm
nvm install --latest-npm v12.22.9

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

npm install 
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done build ..."
else
  echo  "Failed build......"
  exit
fi
npm test
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done Test ......"
else
  echo  "Failed Test ......"
fi
