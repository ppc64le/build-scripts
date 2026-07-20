#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : simplejson
# Version          : v3.17.6
# Source repo      : https://github.com/simplejson/simplejson
# Tested on	: UBI:9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : ICH <ich@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=simplejson
PACKAGE_VERSION=${1:-v3.17.6}
PACKAGE_URL=https://github.com/simplejson/simplejson
PACKAGE_DIR="$(pwd)/$PACKAGE_NAME"

yum install -y git  python3 python3-devel.ppc64le gcc gcc-c++ make wget sudo cmake
pip3 install pytest tox nox
PATH=$PATH:/usr/local/bin/

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)
SOURCE=Github

# Install rust
if ! command -v rustc &> /dev/null
then
    wget https://static.rust-lang.org/dist/rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz
    tar -xzf rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz
    cd rust-1.75.0-powerpc64le-unknown-linux-gnu
    sudo ./install.sh
    export PATH=$HOME/.cargo/bin:$PATH
    rustc -V
    cargo -V
    cd ../
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

# Install via pip3
if !  python3 -m pip install ./; then
        echo "------------------$PACKAGE_NAME:install_fails------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_Failed"  
        exit 1
fi

# Run Pytest
python3 -m pytest
if [ $? -eq 0 ]; then
    echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Pass | Both_Install_and_Test_Success"
    exit 0
else
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_success_but_test_Fails"
    exit 2
fi
