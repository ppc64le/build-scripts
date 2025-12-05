#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : safetensors
# Version       : v0.5.3
# Source repo   : https://github.com/huggingface/safetensors
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Rosman Cariño <rcarino@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


# Variables
PACKAGE_NAME=safetensors
PACKAGE_VERSION=${1:-v0.5.3}
PACKAGE_URL=https://github.com/huggingface/safetensors.git
PACKAGE_DIR=safetensors

# Install dependencies
yum install -y git python3.12 python3.12-devel gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran make wget sudo cmake
pip install --upgrade pip
pip install build maturin

# Install Rust
echo "Installing Rust"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
rustup update
echo "Installed Rust"

export PATH=$PATH:/usr/local/bin/
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
SOURCE=Github

# Clone or extract the package
if [[ "$PACKAGE_URL" == *github.com* ]]; then
    if [ -d "$PACKAGE_DIR" ]; then
        cd "$PACKAGE_DIR" || exit
    else
        if ! git clone "$PACKAGE_URL" "$PACKAGE_DIR"; then
            echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
            echo "$PACKAGE_URL $PACKAGE_NAME"
            echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Clone_Fails"
            exit 1
        fi
        cd "$PACKAGE_DIR" || exit
        git checkout "$PACKAGE_VERSION" || exit
    fi
else
    if [ -d "$PACKAGE_DIR" ]; then
        cd "$PACKAGE_DIR" || exit
    else
        if ! curl -L "$PACKAGE_URL" -o "$PACKAGE_DIR.tar.gz"; then
            echo "------------------$PACKAGE_NAME:download_fails---------------------------------------"
            echo "$PACKAGE_URL $PACKAGE_NAME"
            echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Download_Fails"
            exit 1
        fi
        mkdir "$PACKAGE_DIR"
        if ! tar -xzf "$PACKAGE_DIR.tar.gz" -C "$PACKAGE_DIR" --strip-components=1; then
            echo "------------------$PACKAGE_NAME:untar_fails---------------------------------------"
            echo "$PACKAGE_URL $PACKAGE_NAME"
            echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Untar_Fails"
            exit 1
        fi
        cd "$PACKAGE_DIR" || exit
    fi
fi

cd bindings/python

# Install package
if ! python3 -m pip install ./; then
    echo "------------------$PACKAGE_NAME:install_fails------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_Failed"
    exit 1
fi

#build wheel
if ! python3 -m build --wheel --no-isolation --outdir="$WORKDIR/"; then
    echo "------------------$PACKAGE_NAME: Wheel_build failed ---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Wheel_build_Failure"
    exit 1
else
    echo "------------------$PACKAGE_NAME: Installation and build_wheel successful ---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Installation_and_build_wheel_Success"
    exit 0
fi