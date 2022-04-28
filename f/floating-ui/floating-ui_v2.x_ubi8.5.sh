#!/bin/bash

# ----------------------------------------------------------------------------
# Package               : floating-ui
# Version               : v2.5.4
# Source repo           : https://github.com/floating-ui/floating-ui.git
# Tested on             : UBI 8.5
# Language              : TypeScript, JavaScript, CSS, HTML
# Script License        : Apache License, Version 2 or later
# Travis-Check          : True
# Maintainer            : Prashant Khoje <Prashant.Khoje@ibm.com>
#
# Disclaimer            : This script has been tested in root mode on given
# ==========              platform using the mentioned version of the package.
#                         It may not work as expected with newer versions of the
#                         package and/or distribution. In such case, please
#                         contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex
echo "Popper is now Floating UI!"
echo "Repo redirects https://github.com/popperjs/popper-core.git to https://github.com/floating-ui/floating-ui.git."
REPO="https://github.com/floating-ui/floating-ui.git"
PACKAGE_VERSION=${1:-v2.5.4}
# PACKAGE_VERSION=${1:-v2.11.5}

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)
echo $OS_NAME

# Install dependencies
dnf install -y git java-1.8.0-openjdk
dnf module install -y nodejs:14

cd /opt
git clone $REPO
cd floating-ui
git checkout $PACKAGE_VERSION

npm install --global yarn

# Install yarn dependencies
yarn install
yarn add closure-compiler -W

# Build
sed -i "s#firstSupportedPlatform !== Platform.JAVA#firstSupportedPlatform === Platform.JAVA#g" /opt/floating-ui/node_modules/@ampproject/rollup-plugin-closure-compiler/dist/index.js
sed -i "s#google-closure-compiler-linux#google-closure-compiler-java#g" /opt/floating-ui/node_modules/@ampproject/rollup-plugin-closure-compiler/node_modules/google-closure-compiler/lib/utils.js
if [[ "$PACKAGE_VERSION" == "v2.11.5" ]]
then
    sed -i "s#'--use-mock-keychain',#'--use-mock-keychain', '--disable-gpu', '--disable-software-rasterizer',#g" /opt/floating-ui/node_modules/puppeteer/lib/cjs/puppeteer/node/Launcher.js
    sed -i "s#'--use-mock-keychain',#'--use-mock-keychain', '--disable-gpu', '--disable-software-rasterizer',#g" /opt/floating-ui/node_modules/puppeteer/lib/esm/puppeteer/node/Launcher.js
fi

yarn build

set +ex
