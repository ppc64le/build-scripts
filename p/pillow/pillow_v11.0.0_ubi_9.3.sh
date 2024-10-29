#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pillow
# Version       : 11.0.0
# Source repo   : https://github.com/python-pillow/Pillow
# Tested on     : UBI:9.3
# Language      : Python, C
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Puneet Sharma <Puneet.Sharma21@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=pillow
PACKAGE_VERSION=${1:-11.0.0}
PACKAGE_URL=https://github.com/python-pillow/Pillow/
PYTHON_VER=${2:-"3.11"}

OS_NAME=$(grep '^PRETTY' /etc/os-release | awk -F '=' '{print $2}')

# install core dependencies
yum install -y python${PYTHON_VER} python${PYTHON_VER}-pip python${PYTHON_VER}-devel gcc git

# install pillow's minimum dependencies
yum install -y zlib zlib-devel libjpeg-turbo libjpeg-turbo-devel

# install build tools for wheel generation
python${PYTHON_VER} -m pip install --upgrade pip setuptools wheel pytest

# clone source repository
git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

# check if setup.py file is present
if [ -f "setup.py" ]; then
    echo "setup.py file exists"

    # Build the wheel file
    if ! python${PYTHON_VER} setup.py bdist_wheel ; then
        echo "------------------$PACKAGE_NAME:Build_wheel_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_wheel_Fails"
        exit 1
    fi

    # Install the package from the wheel
    WHEEL_FILE=$(ls dist/*.whl)
    if ! python${PYTHON_VER} -m pip install $WHEEL_FILE ; then
        echo "------------------$PACKAGE_NAME:Install_wheel_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_wheel_Fails"
        exit 1
    fi

else
    echo "setup.py not present"
    exit 1
fi

# Run tests to verify installation
if ! pytest Tests/test_lib_image.py Tests/test_core_resources.py Tests/test_file_jpeg.py Tests/check_png_dos.py Tests/test_file_apng.py Tests/test_file_png.py ; then
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
