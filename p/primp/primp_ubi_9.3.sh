#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package        : primp
# Version        : v0.8.1
# Source repo    : https://github.com/deedy5/primp.git
# Tested on      : UBI 9.3
# Language       : Python
# Ci-Check   : True
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

# Remove Rust-related maturin settings from pyproject.toml
sed -i '/^\[tool\.maturin\]/,/^$/d' pyproject.toml
sed -i '/^\[build-system\]/,/^\[/{/^\[build-system\]/!{/^\[/!d}}' pyproject.toml

# Re-add minimal build-system section for setuptools
sed -i '/^\[build-system\]/a requires = ["setuptools", "wheel"]\nbuild-backend = "setuptools.build_meta"' pyproject.toml

# Remove dynamic versioning
sed -i '/^dynamic *= *\["version"\]/d' pyproject.toml

# Strip leading "v" from PACKAGE_VERSION if present
VERSION="${PACKAGE_VERSION#v}"

# Update pyproject.toml with actual version
sed -i '/^version *=/d' pyproject.toml
sed -i "/^\[project\]/a version = \"$VERSION\"" pyproject.toml

# Install Rust using rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

# Install the package
if ! pip3 install .; then
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
