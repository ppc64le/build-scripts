# ----------------------------------------------------------------------------
#
# Package       : pyarrow
# Version       : 0.10.0
# Source repo   : https://github.com/apache/arrow.git
# Tested on     : nvidia/cuda-ppc64le:9.2-cudnn7-devel-ubuntu16.04
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
#!/bin/bash

export CC=5
export CXX=5

sudo apt update -y --fix-missing && \
    sudo apt upgrade -y && \
    sudo apt install -y \
      git \
      gcc-${CC} \
      g++-${CXX} \
      libboost-all-dev \
      libjemalloc-dev \
      flex \
      bison \
      wget

export WDIR=$HOME
# Install conda
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
mv Miniconda3-latest-Linux-ppc64le.sh $WDIR/miniconda.sh
sudo sh $WDIR/miniconda.sh -b -p /conda && /conda/bin/conda update -n base conda
export PATH=${PATH}:/conda/bin

# Build combined libgdf/pygdf conda env
export PYTHON_VERSION=3.6
conda create -n pyarrow -y python=${PYTHON_VERSION}

export NUMPY_VERSION=1.14.5
export PANDAS_VERSION=0.20.3

conda install -n pyarrow -y -c conda-forge -c defaults \
      numpy=${NUMPY_VERSION} \
      pandas=${PANDAS_VERSION} \
      cmake \
      cython \
      pytest

# Arrow build test install
export ARROW_REPO=https://github.com/apache/arrow.git
mkdir -p $WDIR/repos && \
    git clone --recurse-submodules ${ARROW_REPO} $WDIR/repos/arrow

mkdir -p $WDIR/repos/dist
export CC=/usr/bin/gcc-${CC}
export CXX=/usr/bin/g++-${CXX}
export ARROW_BUILD_TYPE=release
export ARROW_HOME=$WDIR/repos/dist
export LD_LIBRARY_PATH=$WDIR/repos/dist/lib:$LD_LIBRARY_PATH

source activate pyarrow && \
    mkdir -p $WDIR/repos/arrow/cpp/build && \
    cd $WDIR/repos/arrow/cpp/build && \
    cmake -DCMAKE_BUILD_TYPE=$ARROW_BUILD_TYPE \
          -DCMAKE_INSTALL_PREFIX=$ARROW_HOME \
          -DARROW_PYTHON=on \
          -DARROW_BUILD_TESTS=ON \
          .. && \
    make -j4 && \
    make test && \
    sudo make install

# pyArrow build test install
source activate pyarrow && \
    cd $WDIR/repos/arrow/python && \
    python setup.py build_ext --build-type=$ARROW_BUILD_TYPE --inplace && \
    py.test && \
    python setup.py install
