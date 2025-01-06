#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : ipympl
# Version          : 0.9.4
# Source repo      : https://github.com/matplotlib/ipympl.git
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Aastha Sharma <aastha.sharma4@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=ipympl
PACKAGE_VERSION=${1:-0.9.4}
PACKAGE_URL=https://github.com/matplotlib/ipympl.git

# Install necessary system packages
yum install -y --allowerasing curl git gcc gcc-c++ wget bzip2 python-pip python-devel libjpeg-devel libpng-devel libtiff-devel


# Check and install Rust
if ! command -v rustc &> /dev/null; then
    echo "Rust not found. Installing Rust..."
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source "$HOME/.cargo/env"  
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

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME

# Checkout the specific version
git checkout $PACKAGE_VERSION

# Install Python dependencies
pip install setuptools matplotlib ipywidgets numpy pytest nbval build

#install
if ! pip install .; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#run tests
if ! pytest -v; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
