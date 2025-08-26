#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : jquery
# Version       : 3.7.1
# Source repo   : https://github.com/jquery/jquery.git
# Tested on     : UBI 9.5
# Language      : JavaScript
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sanket Patil <Sanket.Patil11@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=jquery
PACKAGE_VERSION=${1:-3.7.1}
PACKAGE_URL=https://github.com/jquery/jquery.git
NODE_VERSION=${NODE_VERSION:-20}
BUILD_HOME=$(pwd)
SCRIPT_PATH=$(dirname "$(realpath "$0")")

# Install dependencies
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os
rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official

yum install -y git wget gcc-c++ make bzip2 libX11 libXext libXtst gtk3 pango atk alsa-lib firefox tar

# Install Node.js using NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
nvm install "${NODE_VERSION}"
nvm alias default "${NODE_VERSION}"
nvm use "${NODE_VERSION}"

# Clone and Checkout jQuery
cd "${BUILD_HOME}"
git clone "${PACKAGE_URL}"
cd "${PACKAGE_NAME}"
git checkout "${PACKAGE_VERSION}"

# Apply patch
git apply ${SCRIPT_PATH}/${PACKAGE_NAME}_${PACKAGE_VERSION}_porting.patch

# Environment Adjustments
export FIREFOX_BIN="/usr/bin/firefox"

npm install
npm install -g grunt-cli

# Build the package
ret=0
grunt custom --filename=jquery.js && grunt || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "ERROR: $PACKAGE_NAME - Build failed."
    exit 1
else
    echo "INFO: $PACKAGE_NAME - Build successful."
fi

# Execute test cases using Grunt and Karma with Firefox
grunt test && grunt karma:main || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "ERROR: $PACKAGE_NAME - Test phase failed."
    exit 2
else
    echo "INFO: $PACKAGE_NAME - All tests passed."
fi

echo "SUCCESS: $PACKAGE_NAME version $PACKAGE_VERSION built and tested successfully."
exit 0
