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
PYTHON_VER=${PYTHON_VERSION:-3.11}

OS_NAME=$(grep '^PRETTY' /etc/os-release | awk -F '=' '{print $2}')

echo "Installing dependencies for Python ${PYTHON_VER}"
yum install -y python${PYTHON_VER} python${PYTHON_VER}-pip python${PYTHON_VER}-devel python${PYTHON_VER}-wheel python${PYTHON_VER}-setuptools git

dnf install -y https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-9.0-24.el9.noarch.rpm \
	https://mirror.stream.centos.org/9-stream/BaseOS/`arch`/os/Packages/centos-stream-repos-9.0-24.el9.noarch.rpm \
	https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/`arch`/os
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/`arch`/os
dnf config-manager --set-enabled crb
dnf install -y g++ cmake libtiff-devel libjpeg-devel openjpeg2-devel zlib-devel \
    freetype-devel lcms2-devel libwebp-devel tcl-devel tk-devel \
    harfbuzz-devel fribidi-devel libraqm-devel libimagequant-devel libxcb-devel

# install build tools for wheel generation
python${PYTHON_VER} -m pip install --upgrade pip setuptools wheel pytest build

if [ -z $PACKAGE_SOURCE_DIR ]; then
  git clone $PACKAGE_URL $PACKAGE_NAME
  cd $PACKAGE_NAME  
else  
  cd $PACKAGE_SOURCE_DIR
fi

git checkout $PACKAGE_VERSION
git submodule update --init --recursive


# Build the wheel file
if ! python${PYTHON_VER} -m build --wheel; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Identify the wheel file specific to this Python version
WHEEL_FILE=$(ls dist/pillow-*-cp${PYTHON_VER//./}*.whl 2>/dev/null)
if [ -z "$WHEEL_FILE" ]; then
    echo "No wheel file found for Python ${PYTHON_VER}"
    ls dist/  # This will list the contents of dist/ to check the wheel files
    exit 1
fi

# Install the package from the wheel
echo "Installing wheel: $WHEEL_FILE for Python ${PYTHON_VER}"
if ! python${PYTHON_VER} -m pip install "$WHEEL_FILE"; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi


export TMPDIR=/tmp/pytest
# Run tests to verify installation
if ! python${PYTHON_VER} -m pytest Tests/test_lib_image.py Tests/test_core_resources.py Tests/test_file_jpeg.py Tests/check_png_dos.py Tests/test_file_apng.py Tests/test_file_png.py ; then
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
