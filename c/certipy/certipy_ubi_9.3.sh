#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : certipy
# Version          : main
# Source repo      : https://github.com/LLNL/certipy.git
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vipul Ajmera <Vipul.Ajmera@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=certipy
PACKAGE_VERSION=${1:-main}
PACKAGE_URL=https://github.com/LLNL/certipy.git

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
  echo "Python 3 not found. Installing Python 3..."
  yum install -y python3 python3-pip python3-devel
  if ! command -v python3 &> /dev/null; then
    echo "Python 3 installation failed."
    exit 1
  fi
else
  echo "Python 3 is already installed."
fi
 
# Ensure pip3 is installed
if ! command -v pip3 &> /dev/null; then
  echo "pip3 not found. Installing pip3..."
  yum install -y python3-pip python3-devel
fi

# Install dependencies
yum install -y --allowerasing yum-utils git gcc gcc-c++ make curl openssl-devel pkg-config
 
# Check if Rust is installed
if ! command -v rustc &> /dev/null; then
  echo "Rust not found. Installing Rust..."
curl https://sh.rustup.rs -sSf | sh -s -- -y
  source "$HOME/.cargo/env"
else
  echo "Rust is already installed."
fi
 
# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
 
# Upgrade pip and install necessary Python packages
python3 -m pip install --upgrade pip
python3 -m pip install build wheel setuptools pypandoc requests flask pytest
 
# Install the package
if ! python3 -m pip install -e .; then
  echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
  echo "$PACKAGE_URL $PACKAGE_NAME"
  echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
  exit 1
fi
 
# Run tests
if ! pytest; then
  echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
  echo "$PACKAGE_URL $PACKAGE_NAME"
  echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_success_but_test_Fails"
  exit 2
else
  echo "------------------$PACKAGE_NAME:Install_&_test_both_success------------------------"
  echo "$PACKAGE_URL $PACKAGE_NAME"
  echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
  exit 0
fi
