#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : black
# Version          : main
# Source repo      : https://github.com/psf/black.git
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Rushikesh.Sathe1@ibm.com
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=black
PACKAGE_VERSION=${1:-26.3.1}
PACKAGE_URL=https://github.com/psf/black.git

# Install dependencies
yum install -y git gcc gcc-c++ make wget openssl-devel bzip2-devel libffi-devel zlib-devel python3.12-devel python3.12-pip

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Check if Rust is installed
if ! command -v rustc &> /dev/null; then
    # If Rust is not found, install Rust
    echo "Rust not found. Installing Rust..."
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "Rust is already installed."
fi

#install necessary Python dependencies
#pip install -r test_requirements.txt

pip install build 

pip install --upgrade pip setuptools wheel
pip install \
    "hatchling>=1.27.0" \
    "hatch-vcs>=0.3.0" \
    "hatch-fancy-pypi-readme"
#install

python3.12 -m build --wheel
if ! (python3.12 -m pip install -e ".[d,jupyter,colorama,uvloop]" ) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

python3.12 -m pip install \
    "tox" \
    "pytest>=7" \
    "pytest-xdist>=3.0.2" \
    "pytest-cov>=4.1.0" \
    "coverage>=5.3"


export PYTEST_ADDOPTS="-n 2"

if ! tox -p 1 -- -n 2 ; then
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
