# ----------------------------------------------------------------------------
#
# Package	: filename-regex
# Version	: 2.0.1
# Source repo	:  https://github.com/regexhq/filename-regex
# Tested on	: ubi 8.5
# Language      : node
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Adilhusain Shaikh <Adilhusain.Shaikh@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="filename-regex"
PACKAGE_VERSION=${1:-"2.0.1"}
PACKAGE_URL="https://github.com/regexhq/filename-regex"
export NODE_VERSION=${NODE_VERSION:-v12.22.4}
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install -y git
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc

nvm install "$NODE_VERSION"
npm install -g npm@latest
npm install -g mocha-cli

HOME_DIR=$PWD

echo "cloning..."
if ! git clone -q "$PACKAGE_URL" $PACKAGE_NAME; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
	exit 1
fi

cd "$HOME_DIR"/$PACKAGE_NAME || exit 1
git checkout "$PACKAGE_VERSION" || exit 1
npm install mocha --save-dev
if ! npm install && npm audit fix; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

cd "$HOME_DIR"/$PACKAGE_NAME || exit 1
if ! npm run | grep -q "test"; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_not_present---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub |  |  Install_success_but_test_not_present"
	exit 0
fi

if ! npm test; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi
