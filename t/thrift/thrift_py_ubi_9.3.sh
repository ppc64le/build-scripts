#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: thrift
# Version	: v0.21.0
# Source repo	: https://github.com/apache/thrift
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

PACKAGE_NAME=thrift
PACKAGE_VERSION=${1:-v0.21.0}
PACKAGE_URL=https://github.com/apache/thrift
PACKAGE_DIR=thrift

yum install -y sudo zlib-devel pip wget python3 python3-devel.ppc64le ncurses git gcc gcc-c++ \
libffi libffi-devel sqlite sqlite-devel sqlite-libs make cmake cargo openssl-devel
pip3 install build

PATH=$PATH:/usr/local/bin/

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)
SOURCE=Github

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
        git checkout "$PACKAGE_VERSION" || exit
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

THRIFT_DIR=$(pwd)

# Install Python 3.11.9
if ! python3.11 --version; then
    cd /usr/src && \
wget https://www.python.org/ftp/python/3.11.9/Python-3.11.9.tgz && \
    tar xzf Python-3.11.9.tgz && \
    cd Python-3.11.9 && \
    ./configure --enable-optimizations && \
    make altinstall && \
    ln -s /usr/local/bin/python3.11 /usr/bin/python3.11 && \
    cd /usr/src && \
    rm -rf Python-3.11.9.tgz Python-3.11.9
    # Manually install pip if it's not installed
    if ! python3.11 -m pip --version; then
wget https://bootstrap.pypa.io/get-pip.py && \
python3.11 get-pip.py && \
rm get-pip.py
    fi
fi

cd "$THRIFT_DIR"
cd lib/py

# create venv
python3.11 -m venv venv
source venv/bin/activate
pip install build

# build wheel
if ! python -m build --wheel --outdir="./"; then
            echo "------------------$PACKAGE_NAME:wheel_build_fails---------------------------------------"
else
            echo "------------------$PACKAGE_NAME:wheel_build_success---------------------------------------"
fi

# cleanup
deactivate
rm -rf venv

exit 0
