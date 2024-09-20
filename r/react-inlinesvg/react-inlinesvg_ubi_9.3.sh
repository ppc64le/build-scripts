#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package	    : react-inlinesvg
# Version	    : v2.3.0
# Source repo	    : https://github.com/gilbarbara/react-inlinesvg
# Tested on	    : UBI 9.3
# Language          : Node
# Travis-Check      : True
# Script License    : MIT License
# Maintainer	    : Prachi Kurade <prachi.kurade1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=react-inlinesvg
PACKAGE_VERSION=${1:-v2.3.0}
PACKAGE_URL=https://github.com/gilbarbara/react-inlinesvg

export NODE_VERSION=${NODE_VERSION:-14}

yum install -y python3 python3-devel.ppc64le git gcc gcc-c++ libffi make wget fontconfig-devel bzip2

#Installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$HOME"/.bashrc
echo "installing nodejs $NODE_VERSION"
nvm install "$NODE_VERSION" >/dev/null
nvm use $NODE_VERSION

#Installing PhantomJS
wget https://github.com/ibmsoe/phantomjs/releases/download/2.1.1/phantomjs-2.1.1-linux-ppc64.tar.bz2
tar -xvf phantomjs-2.1.1-linux-ppc64.tar.bz2
ln -s /phantomjs-2.1.1-linux-ppc64/bin/phantomjs /usr/local/bin/phantomjs
export PATH=$PATH:/phantomjs-2.1.1-linux-ppc64/bin
export OPENSSL_CONF=/etc/ssl


git clone $PACKAGE_URL $PACKAGE_NAME
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! npm install && npm audit fix --force; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#Test cases require local server and cannot be run in a docker container. Command - npm test

echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Install_Success"
exit 0



