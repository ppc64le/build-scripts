#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: htpasswd
# Version	: 2.3
# Source repo	: https://github.com/thesharp/htpasswd
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

PACKAGE_NAME=htpasswd
PACKAGE_VERSION=${1:-2.3}
PACKAGE_URL=https://github.com/thesharp/htpasswd
PACKAGE_DIR=htpasswd

yum install -y git python3.11 python3.11-devel python3.11-pip gcc gcc-c++ make wget sudo cmake
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
        git checkout master || exit
    fi
else
    # If it's not a Git repository, download and untar
    if [ -d "$PACKAGE_DIR" ]; then
        cd "$PACKAGE_DIR" || exit
    else
        # Use download and untar if it's not a Git repository
        if ! curl -L "$PACKAGE_URL" -o "$PACKAGE_DIR.tar.gz"; then
            echo "------------------$PACKAGE_URL:download_fails---------------------------------------"
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

# Install via pip3
if !  python3.11 -m pip install ./; then
        echo "------------------$PACKAGE_NAME:install_fails------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_Failed"  
        exit 1
fi

# build wheel
python3.11 -m venv venv
source venv/bin/activate
python3.11 -m pip install wheel

if ! python3.11 -m pip wheel --no-deps htpasswd==${PACKAGE_VERSION}; then
    echo "--------------------$PACKAGE_NAME:wheel_build_fails----------------------------------------"
    exit 3
else
    echo "--------------------$PACKAGE_NAME:wheel_build_success----------------------------------------"
fi

# cleanup
deactivate
rm -rf venv

exit 0
