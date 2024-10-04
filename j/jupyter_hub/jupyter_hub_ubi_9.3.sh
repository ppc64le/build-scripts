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
yum install -y wget curl python-pip --skip-broken

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

# Step 5: Download and extract the package
echo "Downloading and extracting $PACKAGE_NAME-$PACKAGE_VERSION..."
wget https://files.pythonhosted.org/packages/6a/85/814664a22f6012abf3d7c8e09413a0db56dcc79321a5bb7f0c6855f92417/$PACKAGE_NAME-$PACKAGE_VERSION.tar.gz
tar -xvzf $PACKAGE_NAME-$PACKAGE_VERSION.tar.gz
cd $PACKAGE_NAME-$PACKAGE_VERSION

# Step 6: Install build tool and build the package
echo "Installing build tools and building the package..."
pip install build

# Handle npm dependencies (if any) for the Node.js components
echo "Installing npm dependencies..."
if [ -f "package.json" ]; then
    npm install --progress=false --unsafe-perm || {
        echo "npm install failed, attempting to fix issues with npm audit..."
        npm audit fix --force || echo "Audit fix failed, please resolve manually."
    }
else
    echo "No package.json found, skipping npm install."
fi

# Final step: Build the Python package
python3 -m build || {
    echo "Python package build failed, exiting."
    exit 1
}

echo "Build completed successfully!"
