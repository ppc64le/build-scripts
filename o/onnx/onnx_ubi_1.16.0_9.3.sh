#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : onnx
# Version          : v1.16.0
# Source repo      : https://github.com/onnx/onnx
# Tested on        : UBI:9.3
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=onnx
PACKAGE_VERSION=${1:-v1.16.0}
PACKAGE_URL=https://github.com/onnx/onnx
PACKAGE_DIR=onnx
CURRENT_DIR="${PWD}"

echo "Installing dependencies..."
yum install -y wget git make libtool  gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran libevent-devel zlib-devel openssl-devel python python3 python3-devel cmake gcc-gfortran openblas openblas-devel
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH


cd $CURRENT_DIR
python${PYTHON_VERSION} -m pip install --upgrade pip setuptools wheel ninja chardet
python${PYTHON_VERSION} -m pip install packaging tox pytest build mypy stubs pytest-runner
python${PYTHON_VERSION} -m pip install 'cmake==3.31.6'

echo " ------------------------------------------ Abseil-CPP Cloning ------------------------------------------ "

# Set ABSEIL_VERSION and ABSEIL_URL
ABSEIL_VERSION=20240116.2
ABSEIL_URL="https://github.com/abseil/abseil-cpp"

git clone $ABSEIL_URL -b $ABSEIL_VERSION

echo " ------------------------------------------ Abseil-CPP Cloned ------------------------------------------ "

cd $CURRENT_DIR

# Setting paths and versions
export C_COMPILER=$(which gcc)
export CXX_COMPILER=$(which g++)
export CFLAGS="-std=gnu11"
export CXXFLAGS="-std=gnu++17"
export CMAKE_C_STANDARD=11
export CMAKE_CXX_STANDARD=17
echo "C Compiler set to $C_COMPILER"
echo "CXX Compiler set to $CXX_COMPILER"


LIBPROTO_DIR=$(pwd)
mkdir -p $LIBPROTO_DIR/local/libprotobuf
LIBPROTO_INSTALL=$LIBPROTO_DIR/local/libprotobuf

# Clone Source-code
echo " ------------------------------------------ Libprotobuf Installing ------------------------------------------ "

PACKAGE_VERSION_LIB="v4.25.8"
PACKAGE_GIT_URL="https://github.com/protocolbuffers/protobuf"
git clone $PACKAGE_GIT_URL -b $PACKAGE_VERSION_LIB

# Build libprotobuf
echo "protobuf build starts!!"
cd protobuf
git submodule update --init --recursive
rm -rf ./third_party/googletest | true
rm -rf ./third_party/abseil-cpp | true

cp -r $CURRENT_DIR/abseil-cpp ./third_party/
mkdir build
cd build
cmake -G "Ninja" \
   ${CMAKE_ARGS} \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_C_COMPILER=$C_COMPILER \
    -DCMAKE_CXX_COMPILER=$CXX_COMPILER \
    -DCMAKE_INSTALL_PREFIX=$LIBPROTO_INSTALL \
    -Dprotobuf_BUILD_TESTS=OFF \
    -Dprotobuf_BUILD_LIBUPB=OFF \
    -Dprotobuf_BUILD_SHARED_LIBS=ON \
    -Dprotobuf_ABSL_PROVIDER="module" \
    -DCMAKE_PREFIX_PATH=$ABSEIL_PREFIX \
    -Dprotobuf_JSONCPP_PROVIDER="package" \
    -Dprotobuf_USE_EXTERNAL_GTEST=OFF \
    ..
cmake --build . --verbose
cmake --install .

echo " ------------------------------------------ Libprotobuf Successfully Installed ------------------------------------------ "

cd ..

export PROTOC="$LIBPROTO_INSTALL/bin/protoc"
export LD_LIBRARY_PATH="$ABSEIL_PREFIX/lib:$LIBPROTO_INSTALL/lib64:$LD_LIBRARY_PATH"
export LIBRARY_PATH="$LIBPROTO_INSTALL/lib64:$LD_LIBRARY_PATH"
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION_VERSION=2

# Apply patch
echo "Applying patch from https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/protobuf/set_cpp_to_17_v4.25.3.patch"
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/protobuf/set_cpp_to_17_v4.25.3.patch
git apply set_cpp_to_17_v4.25.3.patch

# Build Python package
cd python
python${PYTHON_VERSION} setup.py install --cpp_implementation

cd $CURRENT_DIR
python${PYTHON_VERSION} -m pip install pybind11==2.12.0
PYBIND11_PREFIX=$SITE_PACKAGE_PATH/pybind11

export CMAKE_PREFIX_PATH="$ABSEIL_PREFIX;$LIBPROTO_INSTALL;$PYBIND11_PREFIX"
echo "Updated CMAKE_PREFIX_PATH after OpenBLAS: $CMAKE_PREFIX_PATH"
export LD_LIBRARY_PATH="$LIBPROTO_INSTALL/lib64:$ABSEIL_PREFIX/lib:$LD_LIBRARY_PATH"
echo "Updated LD_LIBRARY_PATH : $LD_LIBRARY_PATH"
cd $CURRENT_DIR

# Clone ONNX repo
echo "Cloning and installing..."
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init --recursive

echo "installing python dependencies...."
pip3 install pytest nbval pythran
echo "installing numpy.."
pip3 install  'numpy==1.26.4'
echo "installing cython.."
pip3 install cython
echo "installing scipy.."
pip3 install scipy
echo "installing parameterized.."
pip3 install parameterized

export CMAKE_ARGS="-DCMAKE_CXX_FLAGS=-include\ cstdint ${CMAKE_ARGS:-}"

echo "installing..."
if ! pip3 install -e . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! pytest --ignore=onnx/test/reference_evaluator_test.py --ignore=onnx/test/test_backend_reference.py --ignore=onnx/test/reference_evaluator_backend_test.py ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
