#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: 
# Version	: 
# Source repo	: 
# Tested on	: UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: ICH <ich@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=
PACKAGE_VERSION=
PACKAGE_URL=

yum install -y git python3 python3-devel.ppc64le gcc gcc-c++ make wget sudo
pip3 install pytest tox nox
PATH=$PATH:/usr/local/bin/
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
SOURCE=Github

# Check if Node.js is already installed
if ! command -v node &>/dev/null; then
    # Set the NVM directory
    export NVM_DIR="$HOME/.nvm"
    echo "Node.js not found, installing NVM and Node.js..."
    wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
    source "$NVM_DIR/nvm.sh"
    nvm install 18
    nvm use 18
    nvm alias default 18
    # Add Node.js binary to PATH
    export PATH="$NVM_DIR/versions/node/v18.0.0/bin:$PATH"
    echo "Node.js version 18 has been installed and set as default."
else
    echo "Node.js is already installed, skipping installation."
fi


# Installing rust
if ! command -v rustc &>/dev/null; then
    echo "Rust not found, installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    echo "Rust has been installed."
else
    echo "Rust is already installed, skipping installation."
fi

# Installing Go
if ! command -v go &>/dev/null; then
    echo "Go not found, installing Go..."
    wget https://golang.org/dl/go1.21.0.linux-ppc64le.tar.gz
    tar -C /usr/local -xzf go1.21.0.linux-ppc64le.tar.gz
    rm go1.21.0.linux-ppc64le.tar.gz
    export PATH="/usr/local/go/bin:${PATH}"
    echo "Go version 1.21.0 has been installed."
else
    echo "Go is already installed, skipping installation."
fi


if [[ "$PACKAGE_URL" == *github.com* ]]; then
    # Use git clone if it's a Git repository
    if [ -d "$PACKAGE_NAME" ]; then
        cd "$PACKAGE_NAME" || exit
    else
        if ! git clone "$PACKAGE_URL" "$PACKAGE_NAME"; then
            echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
            echo "$PACKAGE_URL $PACKAGE_NAME"
            echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Clone_Fails"   
            exit 1
        fi
        cd "$PACKAGE_NAME" || exit
        git checkout "$PACKAGE_VERSION" || exit
    fi
else
        # If it's not a Git repository, download and untar
    if [ -d "$PACKAGE_NAME" ]; then
        cd "$PACKAGE_NAME" || exit
    else
        # Use download and untar if it's not a Git repository
        if ! curl -L "$PACKAGE_URL" -o "$PACKAGE_NAME.tar.gz"; then
            echo "------------------$PACKAGE_NAME:download_fails---------------------------------------"
            echo "$PACKAGE_URL $PACKAGE_NAME"
            echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Download_Fails"   
            exit 1
        fi
        mkdir "$PACKAGE_NAME"
        # Extract the downloaded tarball
        if ! tar -xzf "$PACKAGE_NAME.tar.gz" -C "$PACKAGE_NAME" --strip-components=1; then
            echo "------------------$PACKAGE_NAME:untar_fails---------------------------------------"
            echo "$PACKAGE_URL $PACKAGE_NAME"
            echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Untar_Fails"   
            exit 1
        fi

        cd "$PACKAGE_NAME" || exit
    fi
fi

# Install via pip
if ! python3 -m pip install ./; then
    echo "------------------$PACKAGE_NAME:install_fails------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_Failed"   
    exit 1
fi

if [ -f "pytest.ini" ] || [ -d "tests" ] || [ -d "test" ] || [ -d "$PACKAGE_NAME/tests" ] || [ -d "$PACKAGE_NAME/test" ]; then
    if ! python3 -m pytest -v; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_success_but_test_Fails"   
        exit 2
    else
        echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME" 
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Pass | Both_Install_and_Test_Success"
        exit 0
    fi

elif [ -f noxfile.py ]; then
    if ! python3 -m nox; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME" 
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_success_but_test_Fails"   
        exit 2
    else
        echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Pass | Both_Install_and_Test_Success" 
        exit 0
    fi
elif [ -f tox.ini ]; then
    if ! python3 -m tox; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME" 
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_success_but_test_Fails"   
        exit 2
    else
        echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Pass | Both_Install_and_Test_Success" 
        exit 0
    fi
else 
    echo "No tests were found"
    exit 0
fi
