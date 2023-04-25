#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: opentelemetry-js-contrib
# Version	: auto-instrumentations-node-v0.36.4
# Source repo	: https://github.com/open-telemetry/opentelemetry-js-contrib
# Tested on	: ubi 8.5
# Language      : node
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer	: Adilhusain Shaikh <Adilhusain.Shaikh@ibm.com>,Pratik Tonage <Pratik.Tonage@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="opentelemetry-js-contrib"
PACKAGE_VERSION=${1:-"auto-instrumentations-node-v0.36.4"}
PACKAGE_URL="https://github.com/open-telemetry/opentelemetry-js-contrib"
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
HOME_DIR=$PWD
export NODE_VERSION=${NODE_VERSION:-16}

echo "insstalling dependencies from system repo..."
dnf install -qy git make gcc-c++ python39-devel
update-alternatives --set python /usr/bin/python3.9
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$HOME"/.bashrc
echo "installing nodejs $NODE_VERSION"
nvm install "$NODE_VERSION" >/dev/null

echo "cloning..."
if ! git clone -q $PACKAGE_URL $PACKAGE_NAME; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
	exit 1
fi

cd $PACKAGE_NAME
git checkout "$PACKAGE_VERSION"
npm config set legacy-peer-deps=true
npm install --ignore-scripts
npx lerna bootstrap --no-ci --hoist --nohoist='zone.js' --nohoist='mocha' --nohoist='ts-mocha'
if ! npm run compile; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

if ! npm run test -- --ignore @opentelemetry/instrumentation-mongoose; then
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

#To run test cases in the Mongoose Instrumentation module, you must first run mongodb in the background.
#That's why when testing we are skipping tests that require mongodb.
#If anyone wants to run those tests,mentioned the steps in README.md to run mongodb in the backround.
#Also need to export variable as below:
#export MONGODB_HOST=<container_ip/container_name>
