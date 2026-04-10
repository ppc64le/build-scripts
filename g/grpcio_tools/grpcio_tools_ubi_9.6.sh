#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : grpcio_tools
# Version       : v1.78.1
# Source repo   : https://github.com/grpc/grpc.git (# For grpcio - https://github.com.mcas.ms/grpc/grpc/tree/master/src/python/grpcio)
# Tested on     : UBI:9.6
# Language      : C++, Python, C, Starlark, Shell, Ruby
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sunidhi.Gaonkar@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=grpcio_tools
PACKAGE_VERSION=${1:-v1.78.1}
PACKAGE_URL=https://github.com/grpc/grpc
WORK_DIR=$(pwd)
PACKAGE_DIR=$WORK_DIR/grpc/tools/distrib/python/grpcio_tools

yum install -y git wget zip unzip \
    python3 python3-devel \
    cmake make openssl-devel gcc g++

# Install absl

git clone https://github.com/abseil/abseil-cpp.git
cd abseil-cpp 
git checkout 20250512.0
mkdir build && cd build
cmake -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
      -DABSL_BUILD_TESTING=OFF \
      -DABSL_ENABLE_INSTALL=ON \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DCMAKE_CXX_STANDARD=17 \
      -DBUILD_SHARED_LIBS=ON ..
make -j$(nproc)
make install
ldconfig
cd $WORK_DIR


#Install protobuf
git clone https://github.com/protocolbuffers/protobuf
cd protobuf
git checkout v6.31.0
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/protobuf/protobuf_v6.31.0.patch
git apply protobuf_v6.31.0.patch
mkdir build && cd build
cmake ..   -DCMAKE_BUILD_TYPE=Release   -Dprotobuf_BUILD_SHARED_LIBS=ON   -Dprotobuf_BUILD_TESTS=OFF   -DCMAKE_PREFIX_PATH=/usr/local
make -j$(nproc)
make install
ldconfig
cd $WORK_DIR

#Build grpcio_tools
git clone $PACKAGE_URL
cd grpc
git checkout $PACKAGE_VERSION
git submodule update --init

cd tools/distrib/python
sed -i '/tools\/bazel query / s/^/#/' bazel_deps.sh
cd $PACKAGE_DIR
python3  ../make_grpcio_tools.py

export GRPC_PYTHON_BUILD_SYSTEM_ABSL=1
export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
export GRPC_PYTHON_BUILD_WITH_CYTHON=1
export GRPC_PYTHON_LDFLAGS="-L/usr/local/lib64 -lprotobuf -lprotoc -labsl_base -labsl_log_severity -labsl_malloc_internal -labsl_poison -labsl_raw_logging_internal -labsl_scoped_set_env -labsl_spinlock_wait -labsl_strerror -labsl_throw_delegate -labsl_tracing_internal -labsl_raw_hash_set"
export LD_LIBRARY_PATH=/usr/local/lib64:$LD_LIBRARY_PATH

python3 -m pip install cython
python3 -m pip install -e .
python3 setup.py bdist_wheel
cp dist/grpcio_tools-*.whl $WORK_DIR

if [ $? == 0 ]; then
     echo "------------------$PACKAGE_NAME::Build_Pass---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Build_Success"
else
     echo "------------------$PACKAGE_NAME::Build_Fail-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Build_Fail"
     exit 1
fi

#Test
python3 -c "from grpc_tools import protoc; from grpc_tools import grpc_version;from grpc_tools import _protoc_compiler; print('All modules imported successfully')"

if [ $? == 0 ]; then
     echo "------------------$PACKAGE_NAME::Test_Pass---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Test_Success"

else
     echo "------------------$PACKAGE_NAME::Test_Fail-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Test_Fail"
     exit 2
fi


