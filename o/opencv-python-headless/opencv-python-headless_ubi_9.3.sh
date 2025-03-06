#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : opencv-python-headless
# Version       : 4.10.0.84
# Source repo   : https://github.com/opencv/opencv-python.git
# Tested on     : UBI 9.3
# Language      : Python, Shell
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e 

PACKAGE_NAME=opencv-python
PACKAGE_VERSION=${1:-84}
PACKAGE_URL=https://github.com/opencv/opencv-python
CURRENT_DIR=$(pwd)
PACKAGE_DIR=opencv-python


echo "------------------------Installing dependencies-------------------"
yum install -y wget
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

dnf install --nodocs -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

# install core dependencies
yum install -y python python python-pip python-devel  gcc-toolset-13 gcc-toolset-13-binutils gcc-toolset-13-binutils-devel gcc-toolset-13-gcc-c++ git ffmpeg-free ffmpeg-free-devel ninja-build make cmake

yum install -y openblas openblas-devel abseil-cpp abseil-cpp-devel protobuf protobuf-devel protobuf-compiler

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
gcc --version

export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

pkg-config --modversion libavcodec


OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

# clone source repository
cd $CURRENT_DIR
git clone --recursive $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

export ENABLE_HEADLESS=1
export CMAKE_ARGS="-DBUILD_TESTS=ON
                   -DCMAKE_BUILD_TYPE=Release
                   -DWITH_EIGEN=1
                   -DBUILD_TESTS=1
                   -DBUILD_ZLIB=0
                   -DBUILD_TIFF=0
                   -DBUILD_PNG=0
                   -DBUILD_JASPER=0
                   -DWITH_ITT=1
                   -DBUILD_JPEG=0
                   -DBUILD_LIBPROTOBUF_FROM_SOURCES=OFF
                   -DWITH_OPENCL=0
                   -DWITH_OPENCLAMDFFT=0
                   -DWITH_OPENCLAMDBLAS=0
                   -DWITH_OPENCL_D3D11_NV=0
                   -DWITH_1394=0
                   -DWITH_CARBON=0
                   -DWITH_OPENNI=0
                   -DWITH_FFMPEG=1
                   -DHAVE_FFMPEG=0
                   -DWITH_JASPER=0
                   -DWITH_VA=0
                   -DWITH_VA_INTEL=0
                   -DWITH_GSTREAMER=0
                   -DWITH_MATLAB=0
                   -DWITH_TESSERACT=0
                   -DWITH_VTK=0
                   -DWITH_GTK=0
                   -DWITH_GPHOTO2=0
                   -DINSTALL_C_EXAMPLES=0
                   -DBUILD_PROTOBUF=OFF
                   -DPROTOBUF_UPDATE_FILES=ON"

# install dependency
python -m pip install --upgrade pip
pip install numpy==2.0.2 pytest scikit-build setuptools build wheel

export C_INCLUDE_PATH=$(python -c "import numpy; print(numpy.get_include())")
export CPLUS_INCLUDE_PATH=$C_INCLUDE_PATH
ln -sf $CURRENT_DIR/opencv-python/tests/SampleVideo_1280x720_1mb.mp4 SampleVideo_1280x720_1mb.mp4

echo "-------------------------------------------------------Building the package-------------------------------------"

#Build package
if ! pip install -e . ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

echo "---------------------------------------------------Print ffmpeg and cv2 version--------------------------------------------------"
python -c "import cv2; print(cv2.__version__)"
python -c "import cv2; print(cv2.getBuildInformation())" | grep -i ffmpeg

echo "---------------------------------------------------Building the wheel--------------------------------------------------"

python setup.py bdist_wheel --dist-dir $CURRENT_DIR

echo "----------------------------------------------Testing pkg-------------------------------------------------------"

#Test package
if ! (python -m unittest discover -s tests) ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi

