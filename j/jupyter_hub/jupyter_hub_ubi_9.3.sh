#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package      : jupyterhub
# Version      : 5.0.0b2
# Source repo : https://github.com/jupyterhub/jupyterhub
# Tested on    : CentOS
# Language     : Python, Node.js
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer   : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------
# Variables
PACKAGE_NAME=jupyterhub
PACKAGE_VERSION=${1:-5.0.0b2}
PACKAGE_URL=https://github.com/jupyterhub/jupyterhub
 
# Step 1: Install required dependencies
echo "Installing required dependencies..."
yum install -y wget curl python-pip --skip-broken
 
# Step 2: Install NVM and Node.js
echo "Installing Node.js 18.17.0..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
nvm install 18.17.0
 
# Step 3: Download and extract the package
echo "Downloading and extracting $PACKAGE_NAME-$PACKAGE_VERSION..."
wget https://files.pythonhosted.org/packages/6a/85/814664a22f6012abf3d7c8e09413a0db56dcc79321a5bb7f0c6855f92417/$PACKAGE_NAME-$PACKAGE_VERSION.tar.gz
tar -xvzf $PACKAGE_NAME-$PACKAGE_VERSION.tar.gz
cd $PACKAGE_NAME-$PACKAGE_VERSION
 
# Step 4: Install build tool and build the package
echo "Installing build tools and building the package..."
pip install build
python3 -m build
