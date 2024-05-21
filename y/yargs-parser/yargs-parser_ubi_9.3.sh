#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : yargs-parser
# Version          : yargs-parser-v21.1.1
# Source repo      : https://github.com/yargs/yargs-parser
# Tested on        : UBI:9.3
# Language         : Javascript,Typescript
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=yargs-parser
PACKAGE_VERSION=${1:-yargs-parser-v21.1.1}
PACKAGE_URL=https://github.com/yargs/yargs-parser
export NODE_VERSION=${NODE_VERSION:-20}

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install -y git wget gcc-c++ gcc libcurl-devel

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$HOME"/.bashrc
echo "installing nodejs $NODE_VERSION"
nvm install "$NODE_VERSION" >/dev/null
nvm use $NODE_VERSION

git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

sed -i '76d' package.json
sed -i '76 i\     "typescript": "4.7.4"' package.json

if ! npm install ; then
       echo "------------------$PACKAGE_NAME:Install_fails---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
       exit 1
fi

if !  npm test ; then
      echo "------------------$PACKAGE_NAME::Install_and_Test_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Fails"
      exit 2
else
      echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
      exit 0
fi
