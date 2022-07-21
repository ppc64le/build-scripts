#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : popper.js (popper-core)
# Version       : v2.10.2
# Source repo   : https://github.com/popperjs/popper-core.git 
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

# variables
PACKAGE_NAME="popper-core"
PACKAGE_VERSION="v2.10.2"
PACKAGE_URL=https://github.com/popperjs/popper-core.git

echo "Usage: $0 [v<PKG_VERSION>]"
echo "       PKG_VERSION is an optional paramater whose default value is v2.10.2"
PKG_VERSION="${1:-$PKG_VERSION}"

#install dependencies
apt-get update && apt-get install -y git build-essential make sed unzip python python3
apt-get install openjdk-8-jdk openjdk-8-jre -y
java -version
cat >> /etc/environment <<EOL
JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
JRE_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre
EOL

#install node
apt-get install curl -y
curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install 14.17.5
node -v
 
#install yarn   
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
apt-get update
apt-get install yarn -y
yarn -v

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


if ! yarn install; then
     	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/install_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails" > /home/tester/output/version_tracker
	exit 1
fi
yarn add closure-compiler -W
   
sed -i "s#firstSupportedPlatform !== Platform.JAVA#firstSupportedPlatform === Platform.JAVA#g" /home/tester/$PACKAGE_NAME/node_modules/@ampproject/rollup-plugin-closure-compiler/dist/index.js
sed -i "s#google-closure-compiler-linux#google-closure-compiler-java#g" /home/tester/$PACKAGE_NAME/node_modules/@ampproject/rollup-plugin-closure-compiler/node_modules/google-closure-compiler/lib/utils.js
sed -i "s#'--use-mock-keychain',#'--use-mock-keychain', '--disable-gpu', '--disable-software-rasterizer',#g" /home/tester/$PACKAGE_NAME/node_modules/puppeteer/lib/cjs/puppeteer/node/Launcher.js
sed -i "s#'--use-mock-keychain',#'--use-mock-keychain', '--disable-gpu', '--disable-software-rasterizer',#g" /home/tester/$PACKAGE_NAME/node_modules/puppeteer/lib/esm/puppeteer/node/Launcher.js
   
if ! yarn build; then
     	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/build_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails" > /home/tester/output/version_tracker
	exit 1
fi