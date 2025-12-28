#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package	    : react-bootstrap-typeahead
# Version	    : v3.4.13
# Source repo	    : https://github.com/codemayonnaise/react-bootstrap-typeahead
# Tested on	    : UBI 9.3
# Language          : Node
# Travis-Check      : True
# Script License    : Apache License, Version 2 or later
# Maintainer	    : Prachi Kurade <prachi.kurade1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=react-bootstrap-typeahead
PACKAGE_VERSION=${1:-v3.4.13}
PACKAGE_URL=https://github.com/codemayonnaise/react-bootstrap-typeahead

export NODE_VERSION=${NODE_VERSION:-10}

yum install -y python3 python3-devel.ppc64le git gcc gcc-c++ libffi make xz

#Installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$HOME"/.bashrc
echo "installing nodejs $NODE_VERSION"
nvm install "$NODE_VERSION" >/dev/null
nvm use $NODE_VERSION

#Installing python2.7
curl -L -O https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tar.xz
tar xf Python-2.7.18.tar.xz
cd Python-2.7.18
./configure --prefix=/usr/local --enable-shared --enable-unicode=ucs4
make && make altinstall
export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/bin/python2.7:$LD_LIBRARY_PATH
cd ../
export PYTHON="$(which python2.7)"

git clone $PACKAGE_URL $PACKAGE_NAME
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION


if ! npm install -g yarn; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! yarn install; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Tests commented because it needs chrome binary to run the test cases. Command is yarn test.
echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass |  Install_Success"
exit 0
