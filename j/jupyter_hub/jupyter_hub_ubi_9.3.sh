#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : jupyterhub
# Version       : 5.0.0b2
# Source repo : https://github.com/jupyterhub/jupyterhub
# Tested on     : CentOS
# Language      : Python, Node.js
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ========== platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such case, please
# contact "Maintainer" of this script.
#
# Note: No test cases are available for this package.
#
# -----------------------------------------------------------------------------
 
# Variables
PACKAGE_NAME=jupyterhub
PACKAGE_VERSION=${1:-5.0.0b2}
PACKAGE_URL=https://github.com/jupyterhub/jupyterhub
 
# Step 1: Install required dependencies
echo "Installing required dependencies..."
yum install -y wget curl
 
# Step 2: Install NVM (Node Version Manager)
echo "Installing NVM..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
 
# Load NVM into the shell session
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
 
# Step 3: Install a compatible version of Node.js
echo "Installing Node.js 18.17.0..."
nvm install 18.17.0
 
# Step 4: Install the latest NPM
echo "Updating NPM..."
npm install -g npm@latest
 
# Step 5: Download the source code
echo "Downloading $PACKAGE_NAME-$PACKAGE_VERSION..."
wget https://files.pythonhosted.org/packages/6a/85/814664a22f6012abf3d7c8e09413a0db56dcc79321a5bb7f0c6855f92417/$PACKAGE_NAME-$PACKAGE_VERSION.tar.gz
 
# Step 6: Extract the tar.gz file
echo "Extracting $PACKAGE_NAME-$PACKAGE_VERSION..."
tar -xvzf $PACKAGE_NAME-$PACKAGE_VERSION.tar.gz
 
# Step 7: Navigate to the extracted directory
cd $PACKAGE_NAME-$PACKAGE_VERSION
 
# Step 8: Install build tool and build the package
echo "Installing build tools..."
pip install build
 
# Echo before building the package
echo "Building the package..."
 
# Build the package
python3 -m build
 
# Optional: Clean up the tar.gz file after extraction
echo "Cleaning up..."
rm ../$PACKAGE_NAME-$PACKAGE_VERSION.tar.gz
 
# Check installation status
if ! python3 -m pip list | grep -q "$PACKAGE_NAME"; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:Install_success-----------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Install_Success"
    exit 0
fi
