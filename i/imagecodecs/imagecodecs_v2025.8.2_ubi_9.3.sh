#!/bin/bash -e
#
# -----------------------------------------------------------------------------
#
# Package           : imagecodecs
# Version           : v2025.8.2
# Source repo       : https://github.com/cgohlke/imagecodecs.git
# Tested on         : UBI:9.3
# Language          : C,Python
# Ci-Check      : True
# Script License    : Apache License, Version 2.0
# Maintainer        : Sakshi Jain <sakshi.jain16@ibm.com>
#
# Disclaimer        : This script has been tested in root mode on given
# ==========          platform using the mentioned version of the package.
#                     It may not work as expected with newer versions of the
#                     package and/or distribution. In such case, please
#                     contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=imagecodecs
PACKAGE_VERSION=${1:-v2025.8.2}
PACKAGE_URL=https://github.com/cgohlke/imagecodecs.git
CURRENT_DIR="${PWD}"

yum install -y wget gcc gcc-c++ gcc-gfortran git make cmake autoconf automake \
    python python3.12 python3.12-devel python3.12-pip openssl-devel perl \
    brotli brotli-devel bzip2 bzip2-devel \
    giflib libpng libpng-devel \
    libwebp libjpeg-turbo libjpeg-turbo-devel  libwebp-devel lz4 lz4-devel xz xz-devel zlib zlib-devel \
    pkgconfig libtool openjpeg2 lcms2

# -------------------------------------------------------------------------
# Python deps (Cython >= 3.1.2, NumPy 2.3.2, Meson/Ninja)
# -------------------------------------------------------------------------
python3.12 -m pip install -U pip setuptools wheel
python3.12 -m pip install "cython>=3.1.2" "numpy==2.3.2" wheel "pytest>=8,<9" meson ninja pylzma

# -------------------------------------------------------------------------
# Install dependencies from source with correct versions
# -------------------------------------------------------------------------

# libtiff 4.7.0
wget https://download.osgeo.org/libtiff/tiff-4.7.0.tar.gz
tar -xzf tiff-4.7.0.tar.gz
cd tiff-4.7.0
./configure --prefix=/usr/local && make -j$(nproc) && make install
cd ..

# libde265
git clone https://github.com/strukturag/libde265.git
cd libde265
./autogen.sh
./configure --prefix=/usr/local
make -j$(nproc) && make install
cd ..

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

# cfitsio 4.2.0
wget https://heasarc.gsfc.nasa.gov/FTP/software/fitsio/c/cfitsio-4.2.0.tar.gz
tar -xf cfitsio-4.2.0.tar.gz &&
cd cfitsio-4.2.0
./configure --prefix=/usr/local && make -j$(nproc) && make install
cd ..

# charls 2.4.2
git clone https://github.com/team-charls/charls.git
cd charls
git checkout 2.4.2
mkdir build
cd build
cmake .. && make -j$(nproc) && make install
cd ../..

# giflib 5.2.1
wget https://downloads.sourceforge.net/project/giflib/giflib-5.2.1.tar.gz
tar -xf giflib-5.2.1.tar.gz && cd giflib-5.2.1
make -j$(nproc)
make install
cd ..

# jxrlib
git clone https://github.com/MoonchildProductions/jxrlib.git
cd jxrlib && make && make install
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

# lerc 4.0.4
git clone --branch v4.0.0 https://github.com/Esri/lerc.git
cd lerc
mkdir cmake_build
cd cmake_build
cmake .. && make -j$(nproc) && make install
cd ../..

# libdeflate 1.24
git clone --branch v1.24 https://github.com/ebiggers/libdeflate.git
cd libdeflate
mkdir build
cd build
cmake .. && make -j$(nproc) && make install
cd ../..

# libheif 1.20.1
git clone --branch v1.20.1 https://github.com/strukturag/libheif.git
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

# openjpeg 2.5.3
git clone --branch v2.5.3 https://github.com/uclouvain/openjpeg.git
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

# lcms2 2.17
wget https://downloads.sourceforge.net/project/lcms/lcms/2.17/lcms2-2.17.tar.gz
tar -xf lcms2-2.17.tar.gz
cd lcms2-2.17
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
python3.12 setup.py install --h5plugin --zstd
cd ..

# libjpeg-turbo 3.1.1
git clone https://github.com/libjpeg-turbo/libjpeg-turbo.git
cd libjpeg-turbo 
git checkout 3.1.1

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
python3.12 setup.py build_ext --inplace

if ! python3.12 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

python3.12 -m pip install build wheel
python3.12 -m build --wheel --no-isolation --outdir="$CURRENT_DIR/"

# -------------------------------------------------------------------------
# Run tests
# -------------------------------------------------------------------------
cd tests
if ! pytest -k "not(test_image_roundtrips or test_tifffile or test_delta or h5checksum)" ; then
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
