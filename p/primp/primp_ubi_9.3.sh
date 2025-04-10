#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package        : primp
# Version        : v0.8.1
# Source repo    : https://github.com/deedy5/primp.git
# Tested on      : UBI 9.3
# Language       : Python
# Travis-Check   : True
# Script License : Apache License, Version 2 or later
# Maintainer     : Vivek Sharma <vivek.sharma20@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such cases, please
#             contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=primp
PACKAGE_VERSION=${1:-v0.8.1}
PACKAGE_DIR=primp
PACKAGE_URL=https://github.com/deedy5/primp.git

# Install necessary system packages
yum install -y git python-devel gcc gcc-c++ gzip tar make wget xz cmake yum-utils \
    openssl-devel openblas-devel bzip2-devel bzip2 zip unzip libffi-devel zlib-devel \
    autoconf automake libtool cargo pkgconf-pkg-config.ppc64le info.ppc64le \
    fontconfig.ppc64le fontconfig-devel.ppc64le sqlite-devel
    
yum remove -y python3-chardet
# Upgrade pip and install required Python packages
python3 -m pip install --upgrade pip
pip3 install setuptools wheel tox

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

# Install Rust using rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

# Install the package
if ! pip install .; then
    echo "------------------$PACKAGE_NAME: Installation failed ---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Installation_Failure"
    exit 1
fi

# Run tests using tox
if ! tox -e py39; then
    echo "------------------$PACKAGE_NAME: Tests_Fail------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Tests_Fail"
    exit 2
else
    echo "------------------$PACKAGE_NAME: Install & test both success ---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
