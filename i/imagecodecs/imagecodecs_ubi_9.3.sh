#!/bin/bash -e
#
# -----------------------------------------------------------------------------
#
# Package           : imagecodecs
# Version           : v2023.1.23
# Source repo       : https://github.com/cgohlke/imagecodecs.git
# Tested on         : UBI:9.3
# Language          : C,Python
# Travis-Check      : True
# Script License    : Apache License, Version 2.0
# Maintainer        : Vinod K<Vinod.K1@ibm.com>
#
# Disclaimer        : This script has been tested in root mode on given
# ==========          platform using the mentioned version of the package.
#                     It may not work as expected with newer versions of the
#                     package and/or distribution. In such case, please
#                     contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=imagecodecs
PACKAGE_VERSION=${1:-v2023.1.23}
PACKAGE_URL=https://github.com/cgohlke/imagecodecs.git
PACKAGE_DIR=./imagecodecs
CURRENT_DIR="${PWD}"
 
yum install -y wget

dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/

# Import CentOS GPG key
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

# Enable EPEL
dnf install --nodocs -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

#Install dependencies which are required for imagecodecs build
yum install -y gcc gcc-c++ gcc-gfortran git make cmake autoconf automake \
    python python-devel openssl-devel perl nasm yasm \
    brotli brotli-devel bzip2 bzip2-devel blosc blosc-devel cfitsio cfitsio-devel \
    CharLS giflib giflib-devel jxrlib jxrlib-devel liblerc lcms2 lcms2-devel \
    libaec libaec-devel libavif libdeflate libdeflate-devel libheif libheif-devel \
    libheif-tools libjpeg-turbo libjpeg-turbo-devel libjxl liblzf libpng libpng-devel \
    libtiff libtiff-devel libtiff-tools libwebp libwebp-devel lz4 lz4-devel \
    openjpeg2 openjpeg2-devel snappy snappy-devel xz xz-devel zlib zlib-devel \
    zlib-ng zopfli zopfli-devel zstd libzstd-devel pkgconfig libtool

# Install libtiff-4.5.1 from source
wget http://download.osgeo.org/libtiff/tiff-4.5.1.tar.gz
tar -xzf tiff-4.5.1.tar.gz
cd tiff-4.5.1
./configure --prefix=/usr/local
make -j$(nproc)
make install
ldconfig
cd ..

# Install libde265 from source
git clone https://github.com/strukturag/libde265.git
cd libde265
./autogen.sh
./configure --prefix=/usr/local
make -j$(nproc)
make install
ldconfig
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH
cd ..

# Install x265 from source
git clone https://github.com/videolan/x265.git
cd x265/build/
cmake ../source -DCMAKE_INSTALL_PREFIX=/usr/local -DENABLE_SHARED=ON -DENABLE_CLI=ON
make -j$(nproc)
make install
ldconfig
ldd /usr/local/bin/x265
echo "/usr/local/lib" > /etc/ld.so.conf.d/x265.conf
ldconfig
x265 --version
cd ../../

pip install numpy==1.23.5 cython==0.29.36 pylzma pytest

git clone PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

export CFLAGS="-I/usr/include/cfitsio"
export LDFLAGS="-L/usr/lib64"

if ! pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

cd tests
# Run test cases
if ! pytest -k "not(test_image_roundtrips)" ; then
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
