#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: htpasswd
# Version	: 2.3
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

PACKAGE_NAME=htpasswd
PACKAGE_VERSION=2.3
PACKAGE_URL=
PACKAGE_DIR=htpasswd

yum install -y sudo zlib-devel pip wget python3 python3-devel.ppc64le ncurses git gcc gcc-c++ \
libffi libffi-devel sqlite sqlite-devel sqlite-libs make cmake cargo openssl-devel
pip3 install build
PATH=$PATH:/usr/local/bin/

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)
mkdir $PACKAGE_DIR
cd $PACKAGE_DIR
HTPASSWD_DIR=$(pwd)

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

cd $HTPASSWD_DIR

# create venv
python3.11 -m venv venv
source venv/bin/activate

# build wheel
if ! python3.11 -m pip wheel htpasswd; then
    echo "--------------------$PACKAGE_NAME:wheel_build_fails----------------------------------------"
else
    echo "--------------------$PACKAGE_NAME:wheel_build_success----------------------------------------"
fi

# cleanup
deactivate
rm -rf venv

exit 0
