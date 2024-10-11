#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pillow
# Version       : 10.3.0
# Source repo   : https://github.com/python-pillow/Pillow
# Tested on     : UBI:9.3
# Language      : Python, C
# Travis-Check  : True
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

PACKAGE_NAME=pillow
PACKAGE_VERSION=${1:-10.3.0}
PACKAGE_URL=https://github.com/python-pillow/Pillow/

OS_NAME=`cat /etc/os-release | grep "PRETTY" | awk -F '=' '{print $2}'`

# install core dependencies
yum install -y python3.11 python3.11-pip python3.11-devel gcc git

# pillow minimum dependencies
yum install -y zlib zlib-devel libjpeg-turbo libjpeg-turbo-devel

# test dependecy
python3.11 -m pip install pytest

# clone source repository
git clone $PACKAGE_URL $PACKAGE_NAME

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

# check if setup.py file is present
if [ -f "setup.py" ];then
        if ! python3.11 setup.py install ; then
        echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
        exit 1
        fi
        echo "setup.py file exists"
else
        echo "setup.py not present"
fi


# check if tests for minimum dependencies pass
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
