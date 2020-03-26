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
JDK_PATHS=$(compgen -G '/usr/lib/jvm/java-1.8.0-openjdk-*')
export JAVA_HOME=${JDK_PATHS%$'\n'*}

WORKDIR=`pwd`

# Build and install python 3.7.3 from source
yum install -y openssl-devel libffi-devel xz-devel
yum install -y http://mirror.centos.org/altarch/7/os/ppc64le/Packages/bzip2-devel-1.0.6-13.el7.ppc64le.rpm
cd /usr/src
wget https://www.python.org/ftp/python/3.7.3/Python-3.7.3.tgz
tar xzf Python-3.7.3.tgz
cd Python-3.7.3
./configure --enable-optimizations
make altinstall
ln -sf /usr/local/bin/python3.7 /usr/bin/python3
ln -sf /usr/local/bin/pip3.7 /usr/local/bin/pip3

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
# Apply fix to memory schedulling test wrt ppc64le
git apply $WORKDIR/patches/test_memory_scheduling.patch
cp $WORKDIR/patches/rules_boost-thread-context-define-ppc.patch ./thirdparty/patches/
cd python
python3.7 -m pip install -v --target ray/pyarrow_files ~/ray_build/pyarrow*.whl
python3.7 setup.py bdist_wheel

# Install dependencies for test execution
pip3.7 install ./dist/ray-0.7.7-cp37-cp37m-linux_ppc64le.whl
pip3.7 install psutil setproctitle grpcio requests networkx tabulate
yum install -y http://mirror.centos.org/altarch/7/os/ppc64le/Packages/blas-3.4.2-8.el7.ppc64le.rpm
yum install -y http://mirror.centos.org/altarch/7/os/ppc64le/Packages/blas-devel-3.4.2-8.el7.ppc64le.rpm
yum install -y http://mirror.centos.org/altarch/7/os/ppc64le/Packages/lapack-3.4.2-8.el7.ppc64le.rpm
yum install -y http://mirror.centos.org/altarch/7/os/ppc64le/Packages/lapack-devel-3.4.2-8.el7.ppc64le.rpm
yum install -y atlas-devel
pip3.7 install scipy==1.3
pip3.7 install gym
pip3.7 install pytest
yum install -y http://mirror.centos.org/altarch/7/os/ppc64le/Packages/swig-2.0.10-5.el7.ppc64le.rpm
yum install -y libcurl-devel.ppc64le patch hdf5-devel.ppc64le gcc-gfortran.ppc64le
pip3.7 install -U numpy
pip3.7 install six wheel portpicker scikit-learn keras

# Build bazel 0.26.1 which is a dependency for building tensorflow
cd $CWD
mkdir bazel_0.26.1
cd bazel_0.26.1
wget https://github.com/bazelbuild/bazel/releases/download/0.26.1/bazel-0.26.1-dist.zip
unzip bazel*
env EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" bash ./compile.sh
cd output
PATH_ORG=$PATH
export PATH=`pwd`:$PATH

# Build and install tensorflow which is a dependency for test execution
cd $CWD
git clone --recurse-submodules https://github.com/tensorflow/tensorflow && \
cd tensorflow && \
git checkout v2.0.1
cp $WORKDIR/patches/tensorflow_io_bazel_rules.patch .
git apply tensorflow_io_bazel_rules.patch
export CC_OPT_FLAGS="-mcpu=power8 -mtune=power8" && \
export GCC_HOST_COMPILER_PATH=/usr/bin/gcc && \
export PYTHON_BIN_PATH=/usr/local/bin/python3.7 && \
export PYTHON_LIB_PATH=/usr/local/lib/ && \
export TF_NEED_GCP=1 && \
export TF_NEED_HDFS=1 && \
export TF_NEED_JEMALLOC=1 && \
export TF_ENABLE_XLA=1 && \
export TF_NEED_OPENCL=0 && \
export TF_NEED_CUDA=0 && \
export TF_NEED_MKL=0 && \
export TF_NEED_VERBS=0 && \
export TF_NEED_MPI=0 && \
export TF_CUDA_CLANG=0 && \
export TF_NEED_OPENCL_SYCL=0 && \
export TF_NEED_ROCM=0 && \
export TF_DOWNLOAD_CLANG=0 && \
export TF_SET_ANDROID_WORKSPACE=0 && \
./configure && \
bazel build -c opt //tensorflow/tools/pip_package:build_pip_package && \
bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg && \
pip3.7 install setuptools==45.2.0
pip3.7 install /tmp/tensorflow_pkg/tensorflow-2.0.*

pip3.7 install aiohttp pandas kubernetes lz4 gputil
yum install -y tmux gdb
yum install -y rh-nodejs12-nodejs
export PATH=$PATH:/opt/rh/rh-nodejs12/root/usr/bin/
cd /usr/local/lib/python3.7/site-packages/ray/dashboard/client/ && npm ci && npm run build && npm update

# Build and install opencv-python-headless which is a dependency for test execution
cd $CWD
git clone https://github.com/skvark/opencv-python.git
cd opencv-python
git checkout tags/30
cp $WORKDIR/patches/opencv-python_setup_py.patch .
git apply opencv-python_setup_py.patch
git config --file=.gitmodules submodule.opencv.url https://github.com/IBM/opencv-power.git
export ENABLE_HEADLESS=1
export CMAKE_ARGS="-DWITH_JPEG=ON -DWITH_OPENCL=OFF \
-DWITH_OPENMP=OFF -DWITH_PTHREADS_PF=OFF \
-DWITH_CUDA=OFF \
-DCMAKE_C_FLAGS="\""-mcpu=power8 -mtune=power8"\"" -DCMAKE_CXX_FLAGS="\""-mcpu=power8 -mtune=power8"\"" \
-DCMAKE_VERBOSE_MAKEFILE=ON \
-DCMAKE_C_COMPILER=/usr/bin/gcc -DCMAKE_CXX_COMPILER=/usr/bin/g++ \
-DPYTHON3_EXECUTABLE=/usr/local/bin/python3.7 \
-DPYTHON3_INCLUDE_DIR=/usr/local/include/python3.7m \
-DPYTHON3_LIBRARY=/usr/local/lib/libpython3.7m.a \
-DPYTHON3_NUMPY_INCLUDE_DIRS=/usr/local/lib/python3.7/site-packages/numpy/core/include/ \
-DPYTHON3_PACKAGES_PATH=/usr/local/lib/python3.7/site-packages"
pip3.7 install --upgrade pip
python3.7 setup.py bdist_wheel
pip3.7 install ./dist/opencv_python_headless-4*

# Trigger ray test execution
export PATH=$PATH_ORG
cd $CWD/ray/doc/examples/cython/
python3.7 setup.py install
cd $CWD/ray
echo "Please note that ray tests are CPU, memory exhaustive. So run these tests on a high end VM."
echo "<= 3 of the following tests may fail (intel result is in parity, failing tests differ over multiple runs):
  //python/ray/tests:test_stress
  //python/ray/tests:test_stress_failure
  //python/ray/tests:test_stress_sharded
  //python/ray/tests:test_debug_tools
  //python/ray/tests:test_basic
  //python/ray/tests:test_dynres
  //python/ray/tests:test_autoscaler_yaml
  //python/ray/tests:test_object_manager
  //python/ray/tests:test_multinode_failures"
bazel test --host_javabase=@local_jdk//:jdk --spawn_strategy=local --test_output=errors --test_tag_filters=-jenkins_only --cache_test_results=no python/ray/tests/...

