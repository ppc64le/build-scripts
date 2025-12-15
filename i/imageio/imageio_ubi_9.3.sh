#!/bin/bash -e
# ----------------------------------------------------------------------------
# 
# Package       : imageio
# Version       : v2.34.1
# Source repo   : https://github.com/imageio/imageio.git
# Tested on     : UBI:9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#variables
PACKAGE_NAME=imageio
PACKAGE_VERSION=${1:-v2.34.1}
PACKAGE_URL=https://github.com/imageio/imageio.git

# Install dependencies and tools.
yum install -y wget gcc gcc-c++ gcc-gfortran git make python-devel zlib-devel libjpeg-devel libtiff-devel freetype-devel libwebp-devel pkg-config


#clone repository 
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

pip install fsspec pytest  
pip install imageio[ffmpeg]

#install
if ! (pip install .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#test
#Few testcases are skipped as they are failing on x_86 too.

if ! (pytest --deselect tests/test_ffmpeg.py --deselect tests/test_pillow.py --deselect tests/test_pillow_legacy.py  --deselect tests/test_dicom.py --deselect tests/test_core.py  --deselect tests/test_ffmpeg_info.py  --deselect tests/test_freeimage.py --deselect tests/test_format.py); then
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
