# ----------------------------------------------------------------------------
#
# Package        : ray-project/ray
# Version        : ray-0.7.7
# Source repo    : https://github.com/ray-project/ray
# Tested on      : RHEL 7.6
# Script License : Apache License, Version 2 or later
# Maintainer     : Amit Sadaphule <amits2@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

# Install dependencies with yum
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install -y gcc gcc-c++ kernel-headers make wget openssl-devel autoconf curl libtool unzip psmisc git zip
yum install -y http://mirror.centos.org/altarch/7/os/ppc64le/Packages/bison-3.0.4-2.el7.ppc64le.rpm
yum install -y http://mirror.centos.org/altarch/7/os/ppc64le/Packages/flex-2.5.37-6.el7.ppc64le.rpm
yum install -y python-devel
yum install -y java-1.8.0-openjdk-devel
export JAVA_HOME=$(compgen -G '/usr/lib/jvm/java-1.8.0-openjdk-*')

WORKDIR=`pwd`

# Build and install python 3.7.3 from source
yum install -y  openssl-devel libffi-devel
yum install -y http://mirror.centos.org/altarch/7/os/ppc64le/Packages/bzip2-devel-1.0.6-13.el7.ppc64le.rpm
cd /usr/src
wget https://www.python.org/ftp/python/3.7.3/Python-3.7.3.tgz
tar xzf Python-3.7.3.tgz
cd Python-3.7.3
./configure --enable-optimizations
make altinstall
ln -s /usr/local/bin/python3.7 /usr/bin/python3

cd $WORKDIR
rm /usr/src/Python-3.7.3.tgz

# Compile and install cmake 3.16.1 (since CMake 3.1 or higher is required for the build)
wget https://github.com/Kitware/CMake/releases/download/v3.16.1/cmake-3.16.1.tar.gz
tar -xzf cmake-3.16.1.tar.gz
cd cmake-3.16.1
./bootstrap
make
make install
cd $WORKDIR && rm -rf cmake-3.16.1.tar.gz cmake-3.16.1

# Install python package dependencies with pip3.7
pip3.7 install scikit-build
pip3.7 install ninja
pip3.7 install cmake
pip3.7 install cython
pip3.7 install numpy

mkdir ~/ray_build
cd ~/ray_build
CWD=`pwd`

# Clone bazel 1.1.0 which is a dependency for the building ray and build it
mkdir bazel_build
cd bazel_build
wget https://github.com/bazelbuild/bazel/releases/download/1.1.0/bazel-1.1.0-dist.zip
unzip bazel*
env EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" bash ./compile.sh
cd output
export PATH=`pwd`:$PATH

cd $CWD

# Clone apache arrow which is a dependency for the building ray and build it
git clone --recursive https://github.com/apache/arrow
cd arrow
git checkout tags/apache-arrow-0.14.0
git submodule update --recursive
mkdir build
cd build
cmake ../cpp -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX=~/ray_build/arrow -DCMAKE_C_FLAGS=-O3 -DCMAKE_CXX_FLAGS=-O3 -DARROW_BUILD_TESTS=off -DARROW_HDFS=on -DARROW_BOOST_USE_SHARED=off -DPYTHON_EXECUTABLE:FILEPATH=/usr/local/bin/python3.7 -DARROW_PYTHON=on -DARROW_PLASMA=on -DARROW_TENSORFLOW=off -DARROW_JEMALLOC=off -DARROW_WITH_BROTLI=off -DARROW_WITH_LZ4=on -DARROW_WITH_ZSTD=off -DARROW_WITH_THRIFT=ON -DARROW_PARQUET=ON -DARROW_WITH_ZLIB=ON
make -j`nproc`
make install
cd ../python
export PKG_CONFIG_PATH=~/ray_build/arrow/lib64/pkgconfig:$PKG_CONFIG_PATH
export PYARROW_BUILD_TYPE='release'
export PYARROW_WITH_ORC=0
export PYARROW_WITH_PARQUET=1
export PYARROW_WITH_PLASMA=1
export PYARROW_BUNDLE_ARROW_CPP=1
pip3.7 install -r requirements-wheel.txt --user
SETUPTOOLS_SCM_PRETEND_VERSION="0.14.0.RAY" python3.7 setup.py build_ext --inplace
SETUPTOOLS_SCM_PRETEND_VERSION="0.14.0.RAY" python3.7 setup.py bdist_wheel
cp dist/pyarrow*.whl $CWD

cd $CWD

# Clone ray 0.7.7 and build
git clone --recursive https://github.com/ray-project/ray
cd ray
git checkout tags/ray-0.7.7
git submodule update --recursive
export SKIP_PYARROW_INSTALL=1
git apply $WORKDIR/patches/ray_boost_plasma_build_fixes.patch
cp $WORKDIR/patches/rules_boost-thread-context-define-ppc.patch ./thirdparty/patches/
cd python
python3.7 -m pip install -v --target ray/pyarrow_files ~/ray_build/pyarrow*.whl
python3.7 setup.py bdist_wheel

# Note that the test case execution is not a part of the build script yet.
# For executing test cases, some other dependecies like tensorflow, opencv-python, opencv-python-headless
# have to be built and installed. Also, some packages which are readily available for ppc64le need to be
# installed using pip3.7. The test case execution and debugging is currently in progress.

