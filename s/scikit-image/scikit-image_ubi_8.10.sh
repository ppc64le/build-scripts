#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : scikit-image
# Version       : v0.22.0
# Source repo   : https://github.com/scikit-image/scikit-image
# Tested on     : UBI 8.10
# Language      : Python, Cython, C, C++
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Salil Verlekar <Salil.Verlekar2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=scikit-image
PACKAGE_VERSION=${1:-v0.22.0}
PACKAGE_URL=https://github.com/scikit-image/scikit-image

OS_NAME=`cat /etc/os-release | grep "PRETTY" | awk -F '=' '{print $2}'`

# install core dependencies
yum install -y gcc gcc-c++ gcc-gfortran pkg-config git python3.11 python3.11-pip python3.11-devel gcc-toolset-10 zlib-devel libjpeg-turbo-devel
yum install -y openblas-devel --enablerepo=codeready-builder-for-rhel-8-ppc64le-rpms

source /opt/rh/gcc-toolset-10/enable

# clone source repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

# Create a virtualenv named ``skimage-dev`` that lives outside of the repository.
mkdir ~/envs
python3.11 -m venv ~/envs/skimage-dev
# Activate it
source ~/envs/skimage-dev/bin/activate

# Install main development and runtime dependencies
python3.11 -m pip install -r requirements.txt

# Install build dependencies of scikit-image
python3.11 -m pip install -r requirements/build.txt

# Install additional dependency  required fro building wheel
python3.11 -m pip install "patchelf>=0.11.0"

# Replace matching numpy version from requirements/build.txt in pyproject to avoid the numpy binary mismatch issue.
sed '1,133s/numpy==1.23.3/numpy>=1.22/' pyproject.toml > tmp.txt
rm -f pyproject.toml
mv tmp.txt pyproject.toml

# build wheel in /scikit-image/dist
if ! python3.11 -m build --wheel --no-isolation; then
        echo "------------------$PACKAGE_NAME:build_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:build_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_Success"
fi

# install wheel
if ! python3.11 -m pip install dist/scikit_image*.whl; then
        echo "------------------$PACKAGE_NAME:install_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
        exit 1
else
        python3.11 -m pip show scikit-image
        echo "------------------$PACKAGE_NAME:install_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_Success"

fi

# test using import
cd skimage
python3.11 -c "import skimage; print(skimage.__version__)"
if [ $? == 0 ]; then
        echo "------------------$PACKAGE_NAME:test_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Test_Success"
	deactivate
        exit 0
else
        echo "------------------$PACKAGE_NAME:test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
        exit 2
fi
