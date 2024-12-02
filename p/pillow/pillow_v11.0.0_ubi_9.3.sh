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

OS_NAME=$(grep '^PRETTY' /etc/os-release | awk -F '=' '{print $2}')

#Instead of using PYTHON_VER or PYTHON_VERSION directly, please use the specific version of Python, such as python3.11.
#Additionally, instead of using the yum command to install setuptools and wheel, please use pip to install them, for example: pip install setuptools

#install dependencies
yum install -y python3.11 python3.11-pip python3.11-devel gcc git
yum install -y zlib zlib-devel libjpeg-turbo libjpeg-turbo-devel

#There's no need to use this symbolic link eg:
#ln -s $(command -v python${PYTHON_VER}) /usr/bin/python 
#ln -s $(command -v pip${PYTHON_VER}) /usr/bin/pip

# install build tools for wheel generation
python3.11 -m pip install --upgrade pip setuptools wheel pytest

# clone source repository
git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

#No need to check setup.py also don't create wheel and install it 
# wheel will be created by wrapper_script
#Use eg:- python setup.py install, pip install ., or pip install -v -e . --no-build-isolation
if ! (python3.11 setup.py install); then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
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
