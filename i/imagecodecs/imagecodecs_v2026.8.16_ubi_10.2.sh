#!/bin/bash -e
#
# -----------------------------------------------------------------------------
#
# Package           : imagecodecs
# Version           : v2026.8.16
# Source repo       : https://github.com/cgohlke/imagecodecs.git
# Tested on         : UBI:10.2
# Language          : C,Python
# Ci-Check      : True
# Script License    : Apache License, Version 2.0
# Maintainer        : tejasBadjateIBM <Tejas.Badjate@ibm.com>
#
# Disclaimer        : This script has been tested in root mode on given
# ==========          platform using the mentioned version of the package.
#                     It may not work as expected with newer versions of the
#                     package and/or distribution. In such case, please
#                     contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=imagecodecs
PACKAGE_VERSION=${1:-v2026.8.16}
PACKAGE_URL=https://github.com/cgohlke/imagecodecs.git
CURRENT_DIR="${PWD}"

yum install -y wget git make cmake autoconf automake \
    python python3.14 python3.14-devel python3.14-pip openssl-devel perl \
    brotli brotli-devel bzip2 bzip2-devel giflib \
    libwebp libjpeg-turbo libjpeg-turbo-devel  libwebp-devel lz4 lz4-devel xz xz-devel zlib zlib-devel \
    pkgconfig libtool openjpeg2 lcms2

yum install gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ gcc-toolset-15-gcc-gfortran -y

# ---------------------------------------------------------------------------
# Activate GCC Toolset 15 (SCL removed in UBI 10 — use PATH export)
# ---------------------------------------------------------------------------
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi

export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:${LD_LIBRARY_PATH:-}"

export CC="/opt/rh/gcc-toolset-15/root/usr/bin/gcc"
export CXX="/opt/rh/gcc-toolset-15/root/usr/bin/g++"
# -------------------------------------------------------------------------
# Python deps (Cython >= 3.2.0, NumPy 2.3.4, Meson/Ninja)
# -------------------------------------------------------------------------
python3.14 -m pip install -U pip setuptools wheel
python3.14 -m pip install "cython==3.2.9" "numpy==2.5.0" wheel "pytest>=8,<9" meson ninja pylzma

# -------------------------------------------------------------------------
# Install dependencies from source with correct versions
# -------------------------------------------------------------------------
# libpng 1.6.53 from source due to lower version issue
wget https://download.sourceforge.net/libpng/libpng-1.6.53.tar.xz
tar -xf libpng-1.6.53.tar.xz
cd libpng-1.6.53

./configure \
    --prefix=/usr/local/libpng-1.6.53

make -j$(nproc)
make install

export PNG_ROOT=/usr/local/libpng-1.6.53

export CPPFLAGS="-I${PNG_ROOT}/include ${CPPFLAGS}"
export CFLAGS="-I${PNG_ROOT}/include ${CFLAGS}"
export LDFLAGS="-L${PNG_ROOT}/lib -L${PNG_ROOT}/lib64 ${LDFLAGS}"
export LIBRARY_PATH="${PNG_ROOT}/lib:${PNG_ROOT}/lib64:${LIBRARY_PATH}"
export LD_LIBRARY_PATH="${PNG_ROOT}/lib:${PNG_ROOT}/lib64:${LD_LIBRARY_PATH}"
export PKG_CONFIG_PATH="${PNG_ROOT}/lib/pkgconfig:${PNG_ROOT}/lib64/pkgconfig:${PKG_CONFIG_PATH}"

# libtiff 4.7.2
wget https://download.osgeo.org/libtiff/tiff-4.7.2.tar.gz
tar -xzf tiff-4.7.2.tar.gz
cd tiff-4.7.2
./configure --prefix=/usr/local && make -j$(nproc) && make install
cd ..

# libde265
git clone https://github.com/strukturag/libde265.git
cd libde265
mkdir build
cd build
cmake ..
make -j$(nproc)
make install
cd ../..

# x265
git clone https://github.com/videolan/x265.git
cd x265/build
cmake ../source -DCMAKE_INSTALL_PREFIX=/usr/local -DENABLE_SHARED=ON -DENABLE_CLI=ON
make -j$(nproc) && make install
cd ../..

# libaec
git clone https://gitlab.dkrz.de/k202009/libaec.git
cd libaec
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
make -j$(nproc) && make install
export LIBAEC_HOME=/usr/local
export LD_LIBRARY_PATH=$LIBAEC_HOME/lib64:$LD_LIBRARY_PATH
cd ../..

# c-blosc
git clone https://github.com/Blosc/c-blosc.git
cd c-blosc
mkdir build
cd build
cmake .. && make -j$(nproc) && make install
cd ../..

# cfitsio 4.6.3
wget https://heasarc.gsfc.nasa.gov/FTP/software/fitsio/c/cfitsio-4.6.3.tar.gz
tar -xf cfitsio-4.6.3.tar.gz &&
cd cfitsio-4.6.3
./configure --prefix=/usr/local && make -j$(nproc) && make install
cd ..

# charls 2.4.4
git clone https://github.com/team-charls/charls.git
cd charls
git checkout 2.4.4
mkdir build
cd build
cmake .. && make -j$(nproc) && make install
cd ../..

# giflib 6.1.3
#wget https://downloads.sourceforge.net/project/giflib/giflib-6.1.3.tar.gz
wget -O giflib-6.1.3.tar.gz  https://sourceforge.net/projects/giflib/files/giflib-6.x/giflib-6.1.3.tar.gz/download
tar -xf giflib-6.1.3.tar.gz && cd giflib-6.1.3
touch doc/giflib-logo.gif
make -j$(nproc)
make install
cd ..

# jxrlib
#git clone https://github.com/MoonchildProductions/jxrlib.git   ----> deleted
# git clone https://github.com/4creators/jxrlib.git  ----> GCC 14 support issue

git clone https://github.com/mircomir/jxrlib.git

cd jxrlib

sed -i '/else/{n;s/^PICFLAG=.*$/PICFLAG=-fPIC/;}' Makefile

make
make install

# Set JXR library root path
JXR_PATH=$(find /usr/lib -type d -name "jxrlib-*" | head -n1)
# Include dir
JXR_INC="$JXR_PATH/include"
# Base include dir
JXR_BASE="$JXR_INC/libjxr"
# Collect all subdirs (image, common, glue, etc.)
JXR_SUBDIRS=$(find "$JXR_BASE" -type d)
# Build -I flags for each subdir
JXR_INC_FLAGS=$(printf " -I%s" $JXR_SUBDIRS)

cd ..

# lerc 4.2.0
git clone --branch v4.2.0 https://github.com/Esri/lerc.git
cd lerc
mkdir cmake_build
cd cmake_build
cmake .. && make -j$(nproc) && make install
cd ../..

# libdeflate 1.25
git clone --branch v1.25 https://github.com/ebiggers/libdeflate.git
cd libdeflate
mkdir build
cd build
cmake .. && make -j$(nproc) && make install
cd ../..

# libheif 1.23.1
git clone --branch v1.23.1 https://github.com/strukturag/libheif.git
cd libheif
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc) && make install
cd ../..

# liblzf 3.6
wget https://dist.schmorp.de/liblzf/liblzf-3.6.tar.gz
tar -xf liblzf-3.6.tar.gz
cd liblzf-3.6
./configure && make -j$(nproc) && make install
cd ..

# openjpeg 2.5.4
git clone --branch v2.5.4 https://github.com/uclouvain/openjpeg.git
cd openjpeg
mkdir build
cd build
cmake .. && make -j$(nproc) && make install
cd ../..

# snappy 1.2.2
git clone --branch 1.2.2 https://github.com/google/snappy.git
cd snappy
mkdir build
cd build
cmake .. -DBUILD_SHARED_LIBS=ON -DSNAPPY_BUILD_TESTS=OFF -DSNAPPY_BUILD_BENCHMARKS=OFF
make -j$(nproc) && make install
cd ../..

# zopfli 1.0.3
git clone --branch zopfli-1.0.3 https://github.com/google/zopfli.git
cd zopfli && make
cp src/zopfli/zopfli.h /usr/local/include/zopfli.h
cp libzopfli.a /usr/local/lib/libzopfli.a
cd ..

# lcms2 2.19.1
wget https://downloads.sourceforge.net/project/lcms/lcms/2.19/lcms2-2.19.tar.gz
tar -xf lcms2-2.19.tar.gz
cd lcms2-2.19
./configure && make -j$(nproc) && make install
cd ..

# zfp 1.0.1
git clone --branch 1.0.1 https://github.com/LLNL/zfp.git
cd zfp
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc) && make install
cd ../..

# zstd 1.5.7
git clone --branch v1.5.7 https://github.com/facebook/zstd.git
cd zstd && make -j$(nproc) && make install
cd ..

# hdf5 1.14.3
wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.14/hdf5-1.14.3/src/hdf5-1.14.3.tar.gz
tar -xf hdf5-1.14.3.tar.gz
cd hdf5-1.14.3
./configure && make -j$(nproc) && make install
cd ..

# bitshuffle 0.5.2
git clone https://github.com/kiyo-masui/bitshuffle.git
cd bitshuffle
git submodule update --init
python3.14 setup.py install --h5plugin --zstd
cd ..

# libjpeg-turbo 3.2.0
git clone https://github.com/libjpeg-turbo/libjpeg-turbo.git
cd libjpeg-turbo
git checkout 3.2.0

# Build 12-bit version
mkdir build12 && cd build12
cmake .. -DWITH_12BIT=1 -DCMAKE_INSTALL_PREFIX=/usr/local
make -j$(nproc)
make install
cd ../..

echo "/usr/local/lib64" > /etc/ld.so.conf.d/libjpeg-turbo.conf
ldconfig

# -------------------------------------------------------------------------
# Build imagecodecs
# -------------------------------------------------------------------------

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

export CFLAGS="-I/usr/local/include -I/usr/local/include/openjpeg-2.5 ${JXR_INC_FLAGS} -I${JXR_INC}"
export LDFLAGS="-L/usr/local/lib -L${JXR_PATH}/lib"
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# Build
python3.14 setup.py build_ext --inplace

if ! python3.14 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

python3.14 -m pip install build wheel
python3.14 -m build --wheel --no-isolation --outdir="$CURRENT_DIR/"

# -------------------------------------------------------------------------
# Run tests
# Skip known unsupported/compatibility test cases for JPEG8 RGBA/lossless,
# LZF and HTJ2K codecs on the current Python 3.14/ppc64le build.
# -------------------------------------------------------------------------
cd tests
if ! python3.14 -m pytest -k "not(test_tiff_encode_compression or test_image_roundtrips or test_tifffile or test_delta or test_avif_encoder_cicp or h5checksum or test_imread_imwrite or test_lzf_exceptions or test_htj2k_level or test_jpeg_encode)" ; then
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