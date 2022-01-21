#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : fbjs
# Version       : v0.6.1
# Source repo   : https://github.com/facebook/fbjs.git
# Tested on     : ubuntu_18.04 (Docker)
# Language      : Node
# Travis-Check  : True
# Script License: MIT License
# Maintainer    : Manik Fulpagar <Manik_Fulpagar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------------------------------

set -ex

# Variables
PACKAGE_NAME="fbjs"
PACKAGE_VERSION=v0.6.1
PACKAGE_URL="https://github.com/facebook/fbjs.git"

echo "Usage: $0 [r<PKG_VERSION>]"
echo "       PKG_VERSION is an optional paramater whose default value is v0.6.1"
PKG_VERSION="${1:-$PKG_VERSION}"

#install dependencies
apt update && apt install -y git wget curl python3

#install nodejs
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install 4
node -v

export HOME=/home/tester

mkdir -p /home/tester/output
cd /home/tester

ln -s /usr/bin/python3 /bin/python

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

function get_checkout_url(){
        url=$1
        CHECKOUT_URL=`python3 -c "url='$url';github_url=url.split('tree')[0];print(github_url);"`
        echo $CHECKOUT_URL
}

function get_working_path(){
        url=$1
        CHECKOUT_URL=`python3 -c "url='$url';github_url,uri=url.split('tree');uris=uri.split('/');print('/'.join(uris[2:]));"`
        echo $CHECKOUT_URL
}

CLONE_URL=$(get_checkout_url $PACKAGE_URL)

if [ "$PACKAGE_URL" = "$CLONE_URL" ]; then
        WORKING_PATH="./"
else
        WORKING_PATH=$(get_working_path $PACKAGE_URL)
fi

if ! git clone $CLONE_URL $PACKAGE_NAME; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
	exit 1
fi

cd /home/tester/$PACKAGE_NAME
git checkout $PACKAGE_VERSION

# run the test command from test.sh
# Build and test package

if ! npm install; then
     	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/install_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails" > /home/tester/output/version_tracker
	exit 1
fi

cd /home/tester/$PACKAGE_NAME
if ! npm run test; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_fails 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_success 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
	exit 0
fi
