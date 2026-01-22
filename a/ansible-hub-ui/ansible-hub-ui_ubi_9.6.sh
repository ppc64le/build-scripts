#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : ansible-hub-ui
# Version          : 4.9.2
# Source repo      : https://github.com/ansible/ansible-hub-ui.git
# Tested on        : UBI 9.6
# Language         : TypeScript
# Ci-Check         : True
# Script License   : GNU General Public License v3.0
# Maintainer       : Haritha Nagothu <haritha.nagothu2@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e
PACKAGE_NAME=ansible-hub-ui
PACKAGE_VERSION=${1:-4.9.2}
PACKAGE_URL=https://github.com/ansible/ansible-hub-ui.git

yum install wget git  make gcc-c++ patch -y

#node installation
export NODE_VERSION=${NODE_VERSION:-20}
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$HOME"/.bashrc
echo "installing nodejs $NODE_VERSION"
nvm install "$NODE_VERSION" >/dev/null
nvm use $NODE_VERSION

git clone $PACKAGE_URL $PACKAGE_NAME
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

sed -i '/"@ls-lint\/ls-lint"/d' package.json
sed -i '/"lint:ls": "ls-lint"/d' package.json

#Install dependencies
if ! npm install ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#Build UI
if ! npm run build-standalone ; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:Build_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Build_Success"
    exit 0
fi
