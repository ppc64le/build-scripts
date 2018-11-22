#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : pygdf
# Version       : v0.1.0a3
# Source repo   : https://github.com/gpuopenanalytics/pygdf
# Tested on     : nvidia/cuda-ppc64le:9.2-cudnn7-devel-centos7, RHEL 7.5
# Script License: Apache License, Version 2 or later
# Maintainer    : Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64:/usr/local/lib
# Needed for pygdf.concat(), avoids "OSError: library nvvm not found"
export NUMBAPRO_NVVM=/usr/local/cuda/nvvm/lib64/libnvvm.so
export NUMBAPRO_LIBDEVICE=/usr/local/cuda/nvvm/libdevice/

#sudo yum update -y && \
sudo yum install -y \
      git \
      make \
      gcc-c++ \
      boost-devel \
      libffi-devel \
      libgfortran \
      flex \
      bison \
      pkgconfig \
      wget \
      bzip2

export WDIR=`pwd`

# Install conda
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
mv Miniconda3-latest-Linux-ppc64le.sh $WDIR/miniconda.sh
sudo sh -c "sh $WDIR/miniconda.sh -b -p /conda && /conda/bin/conda update -n base conda"
export PATH=${PATH}:/conda/bin

# Build combined libgdf/pygdf conda env
export PYTHON_VERSION=3.6
conda create -n gdf -y python=${PYTHON_VERSION}

export NUMBA_VERSION=0.40.0
export NUMPY_VERSION=1.14.5
# Locked to Pandas 0.20.3 by https://github.com/gpuopenanalytics/pygdf/issues/118
export PANDAS_VERSION=0.20.3

conda install -n gdf -y -c numba -c conda-forge -c defaults \
      numba=${NUMBA_VERSION} \
      numpy=${NUMPY_VERSION} \
      pandas=${PANDAS_VERSION} \
      cmake \
      cython \
      pytest

# Arrow build install
export ARROW_REPO=https://github.com/apache/arrow.git
mkdir -p $WDIR/repos && \
    git clone --recurse-submodules ${ARROW_REPO} -b apache-arrow-0.11.0 $WDIR/repos/arrow

mkdir -p $WDIR/repos/dist

export ARROW_BUILD_TYPE=release
export ARROW_HOME=$WDIR/repos/dist
export LD_LIBRARY_PATH=$WDIR/repos/dist/lib64:$LD_LIBRARY_PATH

source activate gdf && \
    mkdir -p $WDIR/repos/arrow/cpp/build && \
    cd $WDIR/repos/arrow/cpp/build && \
    cmake -DCMAKE_BUILD_TYPE=$ARROW_BUILD_TYPE \
          -DCMAKE_INSTALL_PREFIX=$ARROW_HOME \
          -DARROW_PYTHON=on \
          -DARROW_BUILD_TESTS=OFF \
          .. && \
    make -j4 && \
    sudo make install

# pyArrow build install
source activate gdf && \
    cd $WDIR/repos/arrow/python && \
    python setup.py build_ext --build-type=$ARROW_BUILD_TYPE --inplace && \
    python setup.py install


# LibGDF build/install
export LIBGDF_REPO=https://github.com/gpuopenanalytics/libgdf
git clone --recurse-submodules ${LIBGDF_REPO} -b v0.1.0a3 $WDIR/libgdf && \
    cd $WDIR/libgdf && \
    git apply < $WDIR/libgdf_cmake.patch

export CC=/usr/bin/gcc
export CXX=/usr/bin/g++
export HASH_JOIN=ON
source activate gdf && \
    mkdir -p $WDIR/libgdf/build && \
    cd $WDIR/libgdf/build && \
    cmake -DLIB_SUFFIX=64 -DHASH_JOIN=${HASH_JOIN} .. && \
    sudo make -j install && \
    make copy_python && \
    python setup.py install

# PyGDF build/install
export PYGDF_REPO=https://github.com/gpuopenanalytics/pygdf
# To build container against https://github.com/gpuopenanalytics/pygdf/pull/138:
# docker build --build-arg PYGDF_REPO="https://github.com/dantegd/pygdf -b enh-ext-unique-value-counts" -t gdf .
git clone --recurse-submodules ${PYGDF_REPO} -b v0.1.0a3 $WDIR/pygdf && \

source activate gdf && \
    cd $WDIR/pygdf && \
    python setup.py install && \
    py.test
