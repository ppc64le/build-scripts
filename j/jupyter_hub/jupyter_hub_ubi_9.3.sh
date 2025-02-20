#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : jupyterhub
# Version       : 5.0.0b2
# Source repo : https://github.com/jupyterhub/jupyterhub
# Tested on     : CentOS
# Language      : Python, Node.js
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=jupyterhub
PACKAGE_VERSION=${1:-5.0.0b2}
PACKAGE_URL=https://github.com/jupyterhub/jupyterhub

# Step 1: Install required dependencies
echo "Installing required dependencies..."
yum install -y git wget curl python-pip gcc openssl-devel gcc-c++ python python3-devel python3 python3-pip openblas-devel cmake libjpeg-devel zlib-devel freetype-devel  libwebp-devel make python3-setuptools --skip-broken
pip install pytest build wheel ruamel-yaml

# Check if Rust is installed
if ! command -v rustc &> /dev/null; then
    echo "Rust is not installed. Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
else
    echo "Rust is already installed."
fi

# Check and install Node.js
if ! command -v node &> /dev/null; then
    echo "Node.js not found. Installing NVM and Node.js..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    source ~/.bashrc  # Load nvm into the current session
    nvm install node
    nvm use node
else
    echo "Node.js is already installed."
fi

#clone repository
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

echo "Installing npm dependencies..."
if [ -f "package.json" ]; then
    npm install --progress=false --unsafe-perm || {
        echo "npm install failed, attempting to fix issues with npm audit..."
        npm audit fix --force || echo "Audit fix failed, please resolve manually."
    }
else
    echo "No package.json found, skipping npm install."
fi

if ! (python3 -m pip install build && python3 -m build); then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME::Build_Success---------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | Pass | Build_Success"
fi


# Check if the 'tests' folder exists
if [ -d "tests" ]; then
    echo "Debug: 'jupyterhub/tests' directory exists."

    # Run tests using pytest
    if ! pytest ; then
        echo "------------------ $PACKAGE_NAME: build success but test fails ---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_success_but_test_Fails"
        exit 2
    else
        echo "------------------ $PACKAGE_NAME: build & test both success ---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Build_and_Test_Success"
    fi
else
    # Skip tests if 'tests' folder is not available
    echo "------------------ $PACKAGE_NAME: tests skipped as 'tests' folder is not available ---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Tests_Skipped"
fi
