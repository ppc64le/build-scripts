# ----------------------------------------------------------------------------
#
# Package	: caffe
# Version	: 1.0.0-rc5
# Source repo	: https://github.com/BVLC/caffe.git
# Tested on	: rhel_7.2
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

WORKDIR=`pwd`

sudo yum install -y yum-utils
sudo yum-config-manager --enable  "rhel-7-for-power-le-optional-rpms"
sudo yum install -y --nogpgcheck gcc gcc-c++ make doxygen git snappy-devel \
    opencv-devel boost-devel wget tar unzip python yum-utils bzip2 autoconf \
    libtool gcc-gfortran binutils python-devel atlas-devel numpy.ppc64le \
    snappy-devel opencv-devel

# Build cmake
cd $WORKDIR
wget http://www.cmake.org/files/v3.4/cmake-3.4.3.tar.gz
tar -xzvf cmake-3.4.3.tar.gz
cd cmake-3.4.3
./configure && make
sudo make install
export PATH=/usr/local/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# Build protobuf
cd $WORKDIR
git clone https://github.com/google/protobuf.git
cd protobuf
git checkout && ./autogen.sh && ./configure && make && sudo make install

# Build glog
cd $WORKDIR
wget https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/google-glog/glog-0.3.3.tar.gz
tar zxvf glog-0.3.3.tar.gz
cd glog-0.3.3
./configure --build=ppc64le-redhat-linux && make && sudo make install

# Build gflag
cd $WORKDIR
export CXXFLAGS="-fPIC"
wget https://github.com/schuhschuh/gflags/archive/master.zip
unzip master.zip
cd gflags-master
mkdir build
cd build
cmake .. && make VERBOSE=1 && make && sudo make install

# Build lmdb
cd $WORKDIR
git clone https://github.com/LMDB/lmdb
cd lmdb/libraries/liblmdb && make && sudo make install

# Build HDF5
cd $WORKDIR
wget http://www.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8.17/src/hdf5-1.8.17.tar
tar -xf hdf5-1.8.17.tar
cd hdf5-1.8.17
./configure --prefix=/usr/local/hdf5 --build=ppc64le-redhat-linux --enable-cxx
make && sudo make install
export PATH=/usr/local/hdf5:$PATH

# Build Openblas
cd $WORKDIR
git clone https://github.com/xianyi/OpenBLAS.git
cd OpenBLAS && make && sudo make install

# Clone and build leveldb
cd $WORKDIR
git clone https://github.com/google/leveldb.git
cd leveldb
make && \
sudo cp --preserve=links out-static/libleveldb.* /usr/local/lib && \
sudo cp -R include/leveldb /usr/local/include/ && \
sudo ldconfig

# Clone and build caffe package
cd $WORKDIR
git clone https://github.com/BVLC/caffe.git
cd caffe
sed -i.bak '/pycaffe/d' CMakeLists.txt
mkdir build
cd build
cmake .. -DBLAS=open
make all && make runtest && sudo make install
