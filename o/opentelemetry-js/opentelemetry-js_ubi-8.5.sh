#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: opentelemetry-js
# Version	: v1.4.0,1.8.0 
# Source repo	: https://github.com/open-telemetry/opentelemetry-js
# Tested on	: ubi 8.5
# Language      : node
# Travis-Check  : True
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

PACKAGE_NAME="opentelemetry-js"
PACKAGE_VERSION=${1:-"v1.8.0"}
PACKAGE_URL="https://github.com/open-telemetry/opentelemetry-js"
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
export NPM_CONFIG_UNSAFE_PERM=true


npm install --ignore-scripts
          npx lerna bootstrap --no-ci --hoist --nohoist='zone.js' --ignore @opentelemetry/selenium-tests
if ! npm run compile; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

# If api directory is available in the package then first need to run npm run compile in the api directory before running tests 
# because it requires the ESM targets to be generated with npm run compile in the API directory.
  
  if [ -d "api" ]; then
      cd api/
      npm run compile
      cd ..
  fi

if ! npm run test; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 2
fi
