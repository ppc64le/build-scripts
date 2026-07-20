#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : onnxruntime
# Version          : v1.22.0
# Source repo      : https://github.com/microsoft/onnxruntime
# Tested on        : UBI:9.3
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such case, please
# contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=onnxruntime
PACKAGE_VERSION=${1:-v1.22.0}
PACKAGE_URL=https://github.com/microsoft/onnxruntime
PACKAGE_DIR="onnxruntime"
WORK_DIR=$(pwd)
CURRENT_DIR=$(pwd)

echo "Installing dependencies..."
yum install -y git make libtool wget gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran libevent-devel zlib-devel openssl-devel clang python3.11 python3.11-devel python3.11-pip cmake xz bzip2-devel libffi-devel patch ninja-build
PYTHON_VERSION=$(python3.11 --version 2>&1 | cut -d ' ' -f 2 | cut -d '.' -f 1-2)
source /opt/rh/gcc-toolset-13/enable

export CC=gcc
export CXX=g++
export FC=gfortran

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
export SITE_PACKAGE_PATH=/usr/local/lib/python${PYTHON_VERSION}/site-packages

ln -sf $(ls -1 /usr/bin/python3.[0-9]* | grep -E '^/usr/bin/python3\.[0-9]+$' | sort -V | tail -n 1) /usr/bin/python3

# Get Python include path
PYTHON_INCLUDE=$(python3.11 -c "from sysconfig import get_paths; print(get_paths()['include'])")
export CPLUS_INCLUDE_PATH=$PYTHON_INCLUDE:$CPLUS_INCLUDE_PATH
export C_INCLUDE_PATH=$PYTHON_INCLUDE:$C_INCLUDE_PATH

#clone and install openblas from source
git clone https://github.com/OpenMathLib/OpenBLAS
cd OpenBLAS
git checkout v0.3.29
git submodule update --init
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/openblas/pyproject.toml
sed -i "s/{PACKAGE_VERSION}/v0.3.29/g" pyproject.toml
PREFIX=local/openblas
OPENBLAS_SOURCE=$(pwd)

# Set build options
declare -a build_opts

# Fix ctest not automatically discovering tests
LDFLAGS=$(echo "${LDFLAGS}" | sed "s/-Wl,--gc-sections//g")
export CF="${CFLAGS} -Wno-unused-parameter -Wno-old-style-declaration"
unset CFLAGS
export USE_OPENMP=1
build_opts+=(USE_OPENMP=${USE_OPENMP})
export PREFIX=${PREFIX}

# Handle Fortran flags
if [ ! -z "$FFLAGS" ]; then
    export FFLAGS="${FFLAGS/-fopenmp/ }"
    export FFLAGS="${FFLAGS} -frecursive"
    export LAPACK_FFLAGS="${FFLAGS}"
fi
export PLATFORM=$(uname -m)
build_opts+=(BINARY="64")
build_opts+=(DYNAMIC_ARCH=1)
build_opts+=(TARGET="POWER9")
BUILD_BFLOAT16=1

# Placeholder for future builds that may include ILP64 variants.
build_opts+=(INTERFACE64=0)
build_opts+=(SYMBOLSUFFIX="")

# Build LAPACK
build_opts+=(NO_LAPACK=0)

# Enable threading and set the number of threads
build_opts+=(USE_THREAD=1)
build_opts+=(NUM_THREADS=8)

# Disable CPU/memory affinity handling to avoid problems with NumPy and R
build_opts+=(NO_AFFINITY=1)

# Build OpenBLAS
make -j8 ${build_opts[@]} CFLAGS="${CF}" FFLAGS="${FFLAGS}" prefix=${PREFIX}

# Install OpenBLAS
CFLAGS="${CF}" FFLAGS="${FFLAGS}" make install PREFIX="${PREFIX}" ${build_opts[@]}
OpenBLASInstallPATH=$(pwd)/$PREFIX
OpenBLASConfigFile=$(find . -name OpenBLASConfig.cmake)
OpenBLASPCFile=$(find . -name openblas.pc)
sed -i "/OpenBLAS_INCLUDE_DIRS/c\SET(OpenBLAS_INCLUDE_DIRS ${OpenBLASInstallPATH}/include)" ${OpenBLASConfigFile}
sed -i "/OpenBLAS_LIBRARIES/c\SET(OpenBLAS_INCLUDE_DIRS ${OpenBLASInstallPATH}/include)" ${OpenBLASConfigFile}
sed -i "s|libdir=local/openblas/lib|libdir=${OpenBLASInstallPATH}/lib|" ${OpenBLASPCFile}
sed -i "s|includedir=local/openblas/include|includedir=${OpenBLASInstallPATH}/include|" ${OpenBLASPCFile}
export LD_LIBRARY_PATH="$OpenBLASInstallPATH/lib"
export PKG_CONFIG_PATH="$OpenBLASInstallPATH/lib/pkgconfig:${PKG_CONFIG_PATH}"
cd ..

python3.11 -m pip install --upgrade pip
python3.11 -m pip install cmake pip setuptools wheel ninja packaging tox pytest build mypy stubs

# Set ABSEIL_VERSION and ABSEIL_URL
ABSEIL_VERSION=20240116.2
ABSEIL_URL="https://github.com/abseil/abseil-cpp"

# Create and set up working directories
echo "Creating abseil prefix directory at $WORK_DIR/abseil-prefix"
mkdir $WORK_DIR/abseil-prefix
PREFIX=$WORK_DIR/abseil-prefix

# Clone abseil-cpp repository
git clone $ABSEIL_URL -b $ABSEIL_VERSION
cd abseil-cpp
SOURCE_DIR=$(pwd)

# Set up directories for local installation
mkdir -p $SOURCE_DIR/local/abseilcpp
abseilcpp=$SOURCE_DIR/local/abseilcpp

# Create build directory and run cmake
mkdir build
cd build
cmake -G Ninja \
${CMAKE_ARGS} \
-DCMAKE_BUILD_TYPE=Release \
-DCMAKE_CXX_STANDARD=17 \
-DCMAKE_INSTALL_LIBDIR=lib \
-DCMAKE_INSTALL_PREFIX=${PREFIX} \
-DBUILD_SHARED_LIBS=ON \
-DABSL_PROPAGATE_CXX_STD=ON \
-DCMAKE_POSITION_INDEPENDENT_CODE=ON \
..
cmake --build .
cmake --install .

# Copy installation files
cd $WORK_DIR
cp -r  $PREFIX/* $abseilcpp/
echo "abseil-cpp has been installed to $abseilcpp"

# Setting paths and versions
PREFIX=$SITE_PACKAGE_PATH
ABSEIL_PREFIX=$SOURCE_DIR/local/abseilcpp
echo "Setting PREFIX to $PREFIX and ABSEIL_PREFIX to $ABSEIL_PREFIX"

mkdir -p $(pwd)/local/libprotobuf
LIBPROTO_INSTALL=$(pwd)/local/libprotobuf
echo "LIBPROTO_INSTALL set to $LIBPROTO_INSTALL"

# Clone Source-code
PACKAGE_VERSION_LIB="v4.25.3"
PACKAGE_GIT_URL="https://github.com/protocolbuffers/protobuf"
git clone $PACKAGE_GIT_URL -b $PACKAGE_VERSION_LIB

# Build libprotobuf
echo "protobuf build starts!!"
cd protobuf
git submodule update --init --recursive
rm -rf ./third_party/googletest | true
rm -rf ./third_party/abseil-cpp | true
cp -r $WORK_DIR/abseil-cpp ./third_party/
mkdir build
cd build
cmake -G "Ninja" \
${CMAKE_ARGS} \
-DCMAKE_BUILD_TYPE=Release \
-DCMAKE_CXX_STANDARD=17 \
-DCMAKE_C_COMPILER=$CC \
-DCMAKE_CXX_COMPILER=$CXX \
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
python3.11 setup.py install --cpp_implementation
cd ../..
python3.11 -m pip install pybind11==2.12.0
PYBIND11_PREFIX=$SITE_PACKAGE_PATH/pybind11
export CMAKE_PREFIX_PATH="$ABSEIL_PREFIX;$LIBPROTO_INSTALL;$PYBIND11_PREFIX"
echo "Updated CMAKE_PREFIX_PATH after OpenBLAS: $CMAKE_PREFIX_PATH"
export LD_LIBRARY_PATH="$LIBPROTO_INSTALL/lib64:$ABSEIL_PREFIX/lib:$LD_LIBRARY_PATH"
echo "Updated LD_LIBRARY_PATH : $LD_LIBRARY_PATH"
echo "Cloning and installing..."

git clone https://github.com/onnx/onnx
cd onnx
git checkout v1.17.0
git submodule update --init --recursive
sed -i 's|https://github.com/abseil/abseil-cpp/archive/refs/tags/20230125.3.tar.gz|https://github.com/abseil/abseil-cpp/archive/refs/tags/20240116.2.tar.gz|g' CMakeLists.txt && \
sed -i 's|e21faa0de5afbbf8ee96398ef0ef812daf416ad8|bb8a766f3aef8e294a864104b8ff3fc37b393210|g' CMakeLists.txt && \
sed -i 's|https://github.com/protocolbuffers/protobuf/releases/download/v22.3/protobuf-22.3.tar.gz|https://github.com/protocolbuffers/protobuf/archive/refs/tags/v4.25.3.tar.gz|g' CMakeLists.txt && \
sed -i 's|310938afea334b98d7cf915b099ec5de5ae3b5c5|4ba37c659f85c20abb0cc595bfac5e3a385e8e93|g' CMakeLists.txt && \
sed -i 's|set(Protobuf_VERSION "4.22.3")|set(Protobuf_VERSION "v4.25.3")|g' CMakeLists.txt

export ONNX_ML=1
export ONNX_PREFIX=$(pwd)/../onnx-prefix
AR=$gcc_home/bin/ar
LD=$gcc_home/bin/ld
NM=$gcc_home/bin/nm
OBJCOPY=$gcc_home/bin/objcopy
OBJDUMP=$gcc_home/bin/objdump
RANLIB=$gcc_home/bin/ranlib
STRIP=$gcc_home/bin/strip
export CMAKE_ARGS=""
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_INSTALL_PREFIX=$ONNX_PREFIX"
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_AR=${AR}"
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_LINKER=${LD}"
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_NM=${NM}"
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_OBJCOPY=${OBJCOPY}"
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_OBJDUMP=${OBJDUMP}"
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_RANLIB=${RANLIB}"
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_STRIP=${STRIP}"
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_CXX_STANDARD=17"
export CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_PROTOC_EXECUTABLE="$PROTOC" -DProtobuf_LIBRARY="$LIBPROTO_INSTALL/lib64/libprotobuf.so""
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH"

# Adding this source due to - (Unable to detect linker for compiler `cc -Wl,--version`)
source /opt/rh/gcc-toolset-13/enable
python3.11 -m pip install cython meson
python3.11 -m pip install numpy==2.0.2
python3.11 -m pip install parameterized
python3.11 -m pip install pytest nbval pythran mypy-protobuf
python3.11 -m pip install scipy==1.13.1

python3.11 setup.py install
echo "--------------onnx installed------------------"
cd ..

cd $CURRENT_DIR
#Build
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

export CXXFLAGS="-Wno-stringop-overflow"
export CFLAGS="-Wno-stringop-overflow"
export LD_LIBRARY_PATH=/OpenBLAS:/OpenBLAS/libopenblas.so.0:$LD_LIBRARY_PATH
python3.11 -m pip install packaging wheel
NUMPY_INCLUDE=$(python3.11 -c "import numpy; print(numpy.get_include())")
echo "NumPy include path: $NUMPY_INCLUDE"

# Manually defines Python::NumPy for CMake versions with broken NumPy detection
sed -i '193i # Fix for Python::NumPy target not found\nif(NOT TARGET Python::NumPy)\n    find_package(Python3 COMPONENTS NumPy REQUIRED)\n    add_library(Python::NumPy INTERFACE IMPORTED)\n    target_include_directories(Python::NumPy INTERFACE ${Python3_NumPy_INCLUDE_DIR})\n    message(STATUS "Manually defined Python::NumPy with include dir: ${Python3_NumPy_INCLUDE_DIR}")\nendif()\n' $CURRENT_DIR/onnxruntime/cmake/onnxruntime_python.cmake
export CXXFLAGS="-I/usr/local/lib64/python${PYTHON_VERSION}/site-packages/numpy/_core/include/numpy $CXXFLAGS"
sed -i 's|5ea4d05e62d7f954a46b3213f9b2535bdd866803|51982be81bbe52572b54180454df11a3ece9a934|' cmake/deps.txt

# Add Python include path to build environment
export CPLUS_INCLUDE_PATH=$PYTHON_INCLUDE:$CPLUS_INCLUDE_PATH
export C_INCLUDE_PATH=$PYTHON_INCLUDE:$C_INCLUDE_PATH

#Build and test
#Building and testing both is performed in build.sh
if ! (./build.sh \
    --cmake_extra_defines "onnxruntime_PREFER_SYSTEM_LIB=ON" "Protobuf_PROTOC_EXECUTABLE=$PROTO_PREFIX/bin/protoc" "Protobuf_INCLUDE_DIR=$PROTO_PREFIX/include" "onnxruntime_USE_COREML=OFF" "Python3_NumPy_INCLUDE_DIR=$NUMPY_INCLUDE" "CMAKE_POLICY_DEFAULT_CMP0001=NEW" "CMAKE_POLICY_DEFAULT_CMP0002=NEW" "CMAKE_POLICY_VERSION_MINIMUM=3.5" \
    --cmake_generator Ninja \
    --build_shared_lib \
    --config Release \
    --update \
    --build \
    --skip_submodule_sync \
    --allow_running_as_root \
    --compile_no_warning_as_error \
    --build_wheel) ; then
    echo "------------------$PACKAGE_NAME:install_&_test_both_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
fi

cp $CURRENT_DIR/onnxruntime/build/Linux/Release/dist/*.whl "$CURRENT_DIR"
exit 0
