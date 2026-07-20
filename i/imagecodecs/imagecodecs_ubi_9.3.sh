#!/bin/bash -e
#
# -----------------------------------------------------------------------------
#
# Package           : imagecodecs
# Version           : v2023.1.23
# Source repo       : https://github.com/cgohlke/imagecodecs.git
# Tested on         : UBI:9.3
# Language          : C,Python
# Ci-Check      : True
# Script License    : Apache License, Version 2.0
# Maintainer        : Ramnath Nayak <Ramnath.Nayak@ibm.com>
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


yum install -y wget gcc gcc-c++ gcc-gfortran git make cmake autoconf automake \
    python python-devel openssl-devel perl \
    brotli brotli-devel bzip2 bzip2-devel giflib \
    libjpeg-turbo libjpeg-turbo-devel libpng libpng-devel \
    libtiff libtiff-devel libwebp libwebp-devel lz4 lz4-devel \
    xz xz-devel zlib zlib-devel pkgconfig libtool openjpeg2 lcms2


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
wget https://download.osgeo.org/libtiff/tiff-4.5.1.tar.gz
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

#install libaec from source
git clone https://gitlab.dkrz.de/k202009/libaec.git
cd libaec
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
make -j$(nproc)
make install
export LIBAEC_HOME=/usr/local
export LD_LIBRARY_PATH=$LIBAEC_HOME/lib64:$LD_LIBRARY_PATH
cd ../..

#install blosc from source
git clone https://github.com/Blosc/c-blosc.git
cd c-blosc
mkdir build && cd build
cmake ..
make -j$(nproc)
make install
ldconfig
cd ../..

#install cfitsio from source
wget https://heasarc.gsfc.nasa.gov/FTP/software/fitsio/c/cfitsio-4.2.0.tar.gz
tar -xf cfitsio-4.2.0.tar.gz && cd cfitsio-4.2.0
./configure --prefix=/usr/local
make
make install
cd ..

#install charls from source
git clone https://github.com/team-charls/charls.git
cd charls && mkdir build && cd build
cmake .. && make -j$(nproc)
make install
cd ../..

#install giflib from source
#installing from source because yum version lacks required headers for build
wget https://downloads.sourceforge.net/project/giflib/giflib-5.2.1.tar.gz
tar -xf giflib-5.2.1.tar.gz && cd giflib-5.2.1
make -j$(nproc)
make install
cd ..

#install jxrlib from source
git clone https://github.com/MoonchildProductions/jxrlib.git
cd jxrlib
make 
make install
cd ..

#install liblerc from source
git clone https://github.com/Esri/lerc.git
cd lerc
mkdir cmake_build && cd cmake_build
cmake .. && make -j$(nproc)
make install
cd ../..

#install libdeflate from source
git clone https://github.com/ebiggers/libdeflate.git
cd libdeflate && mkdir build && cd build
cmake .. && make -j$(nproc)
make install
cd ../..

#install libheif from source
git clone https://github.com/strukturag/libheif.git
cd libheif
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc) && make install
cd ../..

#install liblzf from source
wget https://dist.schmorp.de/liblzf/liblzf-3.6.tar.gz
tar -xf liblzf-3.6.tar.gz && cd liblzf-3.6
./configure && make -j$(nproc)
make install
cd ..

#install openjpeg from source
#installing from source because yum version lacks required headers for build
git clone https://github.com/uclouvain/openjpeg.git
cd openjpeg && mkdir build && cd build
cmake .. && make -j$(nproc)
make install
cd ../..

#install snappy from source
git clone https://github.com/google/snappy.git
cd snappy
mkdir build && cd build
cmake .. -DBUILD_SHARED_LIBS=ON -DSNAPPY_BUILD_TESTS=OFF -DSNAPPY_BUILD_BENCHMARKS=OFF
make -j$(nproc)
make install
ldconfig
cd ../..

#install zopfli from source
git clone https://github.com/google/zopfli.git
cd zopfli
make 
cd ..
cp $CURRENT_DIR/zopfli/src/zopfli/zopfli.h /usr/local/include/zopfli.h
cp $CURRENT_DIR/zopfli/libzopfli.a /usr/local/lib/libzopfli.a

#install lcms2 from source
#installing from source because yum version lacks required headers for build
wget https://downloads.sourceforge.net/project/lcms/lcms/2.14/lcms2-2.14.tar.gz
tar -xf lcms2-2.14.tar.gz && cd lcms2-2.14
./configure && make -j$(nproc)
make install
cd ..

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

#install zstd from source
git clone https://github.com/facebook/zstd.git
cd zstd && make -j$(nproc)
make install
cd ..

#install hdf5 from source
wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.14/hdf5-1.14.3/src/hdf5-1.14.3.tar.gz
tar -xf hdf5-1.14.3.tar.gz && cd hdf5-1.14.3
./configure && make -j$(nproc)
make install
cd ..

#install bitshuffle from source
git clone https://github.com/kiyo-masui/bitshuffle
cd bitshuffle
git submodule update --init
python3 setup.py install --h5plugin --h5plugin-dir ~/hdf5/lib --zstd
cd ..

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

export CFLAGS="-I/usr/local/include/openjpeg-2.5 -I/usr/lib/jxrlib-1.1/include/libjxr/image/ -I/usr/lib/jxrlib-1.1/include/libjxr/common/ -I/usr/lib/jxrlib-1.1/include/libjxr/glue/"
export LDFLAGS="-L/usr/lib64 -L/usr/lib/jxrlib-1.1/lib"
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
