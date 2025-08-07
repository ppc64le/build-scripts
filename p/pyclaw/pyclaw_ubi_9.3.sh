#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : pyclaw
# Version          : v5.12.0
# Source repo      : https://github.com/clawpack/pyclaw.git
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Aastha Sharma <aastha.sharma4@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------
set -ex

# Define package details
PACKAGE_NAME=pyclaw
PACKAGE_VERSION=${1:-v5.12.0}
PACKAGE_URL=https://github.com/clawpack/pyclaw.git
PACKAGE_DIR=pyclaw/src/pyclaw
CURRENT_DIR=$(pwd)

# --- Install System Dependencies ---
echo "--- Installing system dependencies ---"
yum install -y cmake make git python3.11 python3.11-devel python3.11-pip \
    python3.11-pytest gcc-toolset-13 gfortran zlib-devel libjpeg-devel openblas-devel pkg-config

# --- Enable GCC Toolset 13 ---
echo "--- Enabling GCC toolset 13 ---"
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

# --- Install Python Dependencies ---
echo "--- Installing Python dependencies ---"
python3.11 -m pip install --upgrade pip
python3.11 -m pip install numpy flake8 meson-python ninja pytest coveralls \
    matplotlib setuptools wheel clawpack

# Clone the pyclaw repository.
echo "--- Cloning PyClaw repository ---"
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

# directories expected by the setup.py script.
#cd /pyclaw/src/pyclaw/
echo "--- Creating necessary directories ---"
mkdir pyclaw
mkdir -p pyclaw/examples
cd pyclaw/examples
touch __init__.py
cd $CURRENT_DIR
cd $PACKAGE_DIR
#ensures that the version is correctly recognized during the build process
sed -i "s/setup(\*\*configuration(top_path='').todict())/setup(version='5.12.0', **configuration(top_path='').todict())/" setup.py

#Explicitly set Fortran compiler environment variables ---
echo "--- Setting Fortran compiler environment variables ---"
export F77=gfortran
export F90=gfortran
export FC=gfortran

# Use pip to install the package from the current source directory.
if ! python3.11 setup.py install ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

#no tests to be run
