# ----------------------------------------------------------------------------
#
# Package       : pyArrow
# Version       : 1.0.1
# Source repo   : https://github.com/apache/arrow
# Tested on     : rhel_7.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Shivani Junawane <shivanij@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Install Pre-requisites
yum install -y wget git

# Install Conda
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
sh Miniconda3-latest-Linux-ppc64le.sh -u -b -p $HOME/conda
$HOME/conda/bin/conda update -y -n base conda
export PATH=$HOME/conda/bin/:$PATH
conda init bash
eval "$(conda shell.bash hook)"
conda config --add channels conda-forge

# Arrow build and install
mkdir repos
cd repos
git clone https://github.com/apache/arrow.git
cd arrow && git checkout apache-arrow-1.0.1 
cd ..
pushd arrow
git submodule init
git submodule update
export PARQUET_TEST_DATA="${PWD}/cpp/submodules/parquet-testing/data"
export ARROW_TEST_DATA="${PWD}/testing/data"
popd

# Create conda channel
sed -i 's/benchmark/#benchmark/g' arrow/ci/conda_env_cpp.yml
sed -i 's/gtest=/gtest>=/g' arrow/ci/conda_env_cpp.yml
conda create -y -n pyarrow-dev -c conda-forge \
    --file arrow/ci/conda_env_unix.yml \
    --file arrow/ci/conda_env_cpp.yml \
    --file arrow/ci/conda_env_python.yml \
    --file arrow/ci/conda_env_gandiva.yml \
    compilers \
    python=3.7 \
    pandas
conda activate pyarrow-dev
conda install -y cmake=3.16.3
export ARROW_HOME=$CONDA_PREFIX

mkdir arrow/cpp/build
pushd arrow/cpp/build

cmake -DCMAKE_INSTALL_PREFIX=$ARROW_HOME \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DARROW_WITH_BZ2=ON \
      -DARROW_WITH_ZLIB=ON \
      -DARROW_WITH_ZSTD=ON \
      -DARROW_WITH_LZ4=ON \
      -DARROW_WITH_SNAPPY=ON \
      -DARROW_WITH_BROTLI=ON \
      -DARROW_PARQUET=ON \
      -DARROW_PYTHON=ON \
      -DARROW_BUILD_TESTS=ON \
      ..
make -j4
make install
popd

pushd arrow/python
export PYARROW_WITH_PARQUET=1
python setup.py build_ext --inplace
python setup.py build_ext --build-type="release" --bundle-arrow-cpp bdist_wheel
popd
