#!/usr/bin/env bash
# -----------------------------------------------------------------
#
# Package        : Pillow
# Version        : 11.1.0
# Source repo    : https://github.com/python-pillow/Pillow
# Tested on      : UBI 9.3
# Language       : Python
# Travis-Check   : True
# Script License : Apache License, Version 2 or later
# Maintainer     : Onkar Kubal <onkar.kubal@ibm.com>
#
# Disclaimer     : This script has been tested in root mode on given
# ==========       platform using the mentioned version of the package.
#                  It may not work as expected with newer versions of the
#                  package and/or distribution. In such case, please
#                  contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e
PACKAGE_NAME=Pillow
SCRIPT_PACKAGE_VERSION=main
PACKAGE_VERSION=11.1.0
PACKAGE_URL=https://github.com/python-pillow/Pillow
SCRIPT_PATH=$(dirname $(realpath $0))
BUILD_HOME=$(pwd)
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)
PYTHON_VER=${2:-3.12}
OPENJPEG_URL=https://github.com/uclouvain/openjpeg
OPENJPEG_VERSION=v2.5.3
OPENJPEG_PACKAGE=openjpeg
LIL_CMS_URL=https://github.com/mm2/Little-CMS
LIL_CMS_PACKAGE=Little-CMS
LIL_CMS_VERSION=lcms2.17
RAQM_URL=https://github.com/HOST-Oman/libraqm
RAQM_PACKAGE=libraqm
RAQM_VERSION=v0.10.2

# Update and install dependencies
yum update -y && yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
 make gcc gcc-c++ cmake wget git python${PYTHON_VER}-devel python${PYTHON_VER}-wheel python${PYTHON_VER}-pip python${PYTHON_VER}-setuptools libjpeg-devel \
 freetype-devel libtiff-devel libffi-devel \
 libxml2-devel libxslt-devel zlib-devel python${PYTHON_VER}-tkinter.ppc64le libwebp.ppc64le libwebp-devel.ppc64le \
 libX11-xcb.ppc64le libxcb.ppc64le libxcb-devel.ppc64le openjpeg2.ppc64le glibc-langpack-en.ppc64le \
 ghostscript python3-pyqt5-sip.ppc64le \
 python3-devel redhat-rpm-config meson freetype.ppc64le

cd $BUILD_HOME

wget https://www.rpmfind.net/linux/centos-stream/9-stream/AppStream/ppc64le/os/Packages/netpbm-10.95.00-2.el9.ppc64le.rpm
yum localinstall netpbm-10.95.00-2.el9.ppc64le.rpm -y

wget https://rpmfind.net/linux/epel/9/Everything/ppc64le/Packages/l/libimagequant-devel-2.17.0-1.el9.ppc64le.rpm
yum localinstall libimagequant-devel-2.17.0-1.el9.ppc64le.rpm -y

rm -rf *.rpm

# Download OpenJPEG
git clone ${OPENJPEG_URL}
cd ${OPENJPEG_PACKAGE}
git checkout ${OPENJPEG_VERSION}
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make
make install
make clean
cd /
cd $BUILD_HOME

# Download Little CMS
git clone ${LIL_CMS_URL}
cd ${LIL_CMS_PACKAGE}
git checkout ${LIL_CMS_VERSION}
./configure --prefix=/usr --disable-static
make
make install
make clean
cd /
cd $BUILD_HOME

rm -rf ${LIL_CMS_PACKAGE} ${OPENJPEG_PACKAGE}

if ! command -v python; then
    ln -s $(command -v python${PYTHON_VER}) /usr/bin/python
fi
if ! command -v pip; then
    ln -s $(command -v pip${PYTHON_VER}) /usr/bin/pip
fi
pip install --upgrade pip
python --version
python -m venv pillow-dev
source ./pillow-dev/bin/activate
# python -m PIL

# Download Pillow
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME}
git pull -f
git checkout ${PACKAGE_VERSION}

pip install webp ipython olefile pyroma
# check if setup.py file is present
if [ -f "setup.py" ]; then
    echo "setup.py file exists"
    # Build the wheel file
    if ! python setup.py bdist_wheel ; then
        echo "------------------$PACKAGE_NAME:Build_wheel_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_wheel_Fails"
        exit 1
    fi
    # Install the package from the wheel
    WHEEL_FILE=$(ls dist/*.whl)
    if ! python -m pip install $WHEEL_FILE ; then
        echo "------------------$PACKAGE_NAME:Install_wheel_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_wheel_Fails"
        exit 1
    fi
else
    echo "setup.py not present"
    exit 1
fi
pip list
pip install pytest pytest-cov pytest-timeout
# Run tests to verify installation
if ! pytest; then
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