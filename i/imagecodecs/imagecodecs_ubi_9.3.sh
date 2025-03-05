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

yum install -y gcc gcc-c++ gcc-gfortran git make cmake autoconf automake \
    python python-devel openssl-devel perl nasm yasm \
    brotli brotli-devel bzip2 bzip2-devel blosc blosc-devel cfitsio cfitsio-devel \
    CharLS giflib giflib-devel jxrlib jxrlib-devel liblerc lcms2 lcms2-devel \
    libaec libaec-devel libavif libdeflate libdeflate-devel libheif libheif-devel \
    libheif-tools libjpeg-turbo libjpeg-turbo-devel libjxl liblzf libpng libpng-devel \
    libtiff libtiff-devel libtiff-tools libwebp libwebp-devel lz4 lz4-devel \
    openjpeg2 openjpeg2-devel snappy snappy-devel xz xz-devel zlib zlib-devel \
    zlib-ng zopfli zopfli-devel zstd libzstd-devel pkgconfig libtool hdf5 hdf5-devel


echo "Checking Python version..."
PYTHON_VERSION=$(python3 -c "import sys; print('.'.join(map(str, sys.version_info[:2])))")
IFS='.' read -r MAJOR MINOR <<< "$PYTHON_VERSION"
if [[ "$MAJOR" -gt 3 ]] || { [[ "$MAJOR" -eq 3 ]] && [[ "$MINOR" -ge 12 ]]; }; then
    echo "Python version is >= 3.11, installing numpy 2.2.2..."
    pip install cython==0.29.36 numpy==2.2.3 wheel pylzma pytest
else
    echo "Python version is < 3.11, installing numpy 1.23.5..."
    pip install cython==0.29.36 numpy==1.26.4 wheel pylzma pytest
fi
# Installing below dependencies from source as those are not able to install from yum
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

#install zfp
git clone https://github.com/LLNL/zfp
cd zfp
mkdir build
cmake -B /zfp/build/ -DCMAKE_BUILD_TYPE=Release -DBUILD_ZFPY=ON
cmake --build /zfp/build --target all --config Release
export LD_LIBRARY_PATH=/zfp/build/lib64:$LD_LIBRARY_PATH
ldconfig
cd ..

#install brunsli
git clone https://github.com/google/brunsli
cd brunsli
cmake ./
make -j
make -j install
cd ..

#install bitshuffle
yum install hdf5 hdf5-devel
git clone https://github.com/kiyo-masui/bitshuffle
cd bitshuffle
git submodule update --init
python3 setup.py install --h5plugin --h5plugin-dir ~/hdf5/lib --zstd
cd ..

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

export CFLAGS="-I/usr/include/cfitsio"
export LDFLAGS="-L/usr/lib64"
python3 setup.py build_ext --inplace

if ! pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

cd tests

# Run test cases
if ! pytest -k "not(test_image_roundtrips or test_tifffile or test_delta)" ; then
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
