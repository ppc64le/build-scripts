#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : jquery-ui
# Version       : v1.14.1
# Source repo   : https://github.com/jquery/jquery-ui
# Tested on     : UBI 9.5 (ppc64le)
# Language      : JavaScript
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : Sanket Patil <Sanket.Patil11@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME="jquery-ui"
PACKAGE_VERSION="${1:-1.14.1}"
PACKAGE_URL="https://github.com/jquery/jquery-ui"
NODE_VERSION=v20.14.0
WORK_DIR=$(pwd)
SCRIPT_PATH=$(dirname "$(realpath "$0")")

yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os
rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official

yum install -y git fontconfig-devel.ppc64le wget curl libXcomposite libXcursor procps-ng java-11-openjdk-devel alsa-lib atk cups-libs gtk3 libXcursor libXdamage libXext libXi libXrandr libXScrnSaver libXtst pango gcc make firefox --allowerasing

export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

source "$NVM_DIR/nvm.sh"
nvm install "$NODE_VERSION"
nvm use "$NODE_VERSION"
nvm alias default "$NODE_VERSION"
export PATH="$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH"

curl https://sh.rustup.rs -sSf | sh -s -- -y
source $HOME/.cargo/env
export PATH=$PATH:/root/.cargo/bin
cargo install geckodriver

# Clone Repository
cd "$WORK_DIR"
rm -rf "$PACKAGE_NAME"
git clone "$PACKAGE_URL"
cd "$PACKAGE_NAME"
git checkout "$PACKAGE_VERSION"

#Apply Patch
git apply ${SCRIPT_PATH}/${PACKAGE_NAME}_${PACKAGE_VERSION}_porting.patch

# Build the package
ret=0
npm install || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "ERROR: $PACKAGE_NAME - Build failed."
    exit 1
else
    echo "INFO: $PACKAGE_NAME - Build successful."
fi

# Run tests
# Skipping flaky test (Sortable: Incorrect revert animation with axis : 'y')
npm test -- --browser firefox || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "ERROR: $PACKAGE_NAME - Test phase failed."
    exit 2
else
    echo "INFO: $PACKAGE_NAME - All tests passed."
fi

echo "SUCCESS: $PACKAGE_NAME version $PACKAGE_VERSION built and tested successfully."
exit 0
