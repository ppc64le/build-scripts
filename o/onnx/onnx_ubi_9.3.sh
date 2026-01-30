#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : onnx
# Version          : v1.19.0
# Source repo      : https://github.com/onnx/onnx
# Tested on        : UBI:9.3
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Sakshi Jain <sakshi.jain16@ibm.com>
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
PACKAGE_VERSION=${1:-v1.19.0}
PACKAGE_URL=https://github.com/onnx/onnx
PACKAGE_DIR=onnx
CURRENT_DIR="${PWD}"

echo "Installing dependencies..."
yum install -y git make libtool wget gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran libevent-devel zlib-devel openssl-devel clang python3.12-devel python3.12 python3.12-pip cmake xz bzip2-devel libffi-devel patch ninja-build
export PYTHON_VERSION=$(python3.12 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
export SITE_PACKAGE_PATH=/usr/local/lib/python${PYTHON_VERSION}/site-packages

echo " ------------------------------------------ Openblas Installing ------------------------------------------ "

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

echo " ------------------------------------------ Openblas Successfully Installed ------------------------------------------ "


cd $CURRENT_DIR

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

python${PYTHON_VERSION} -m pip install --upgrade pip setuptools wheel ninja
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

echo " ------------------------------------------ Onnx Installing ------------------------------------------ "

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init --recursive
sed -i 's|https://github.com/abseil/abseil-cpp/archive/refs/tags/20230125.3.tar.gz%7Chttps://github.com/abseil/abseil-cpp/archive/refs/tags/20240116.2.tar.gz%7Cg' CMakeLists.txt && \
sed -i 's|e21faa0de5afbbf8ee96398ef0ef812daf416ad8|bb8a766f3aef8e294a864104b8ff3fc37b393210|g' CMakeLists.txt && \
sed -i 's|https://github.com/protocolbuffers/protobuf/releases/download/v22.3/protobuf-22.3.tar.gz%7Chttps://github.com/protocolbuffers/protobuf/archive/refs/tags/v4.25.8.tar.gz%7Cg' CMakeLists.txt && \
sed -i 's|310938afea334b98d7cf915b099ec5de5ae3b5c5|ffa977b9a7fb7e6ae537528eeae58c1c4d661071|g' CMakeLists.txt && \
sed -i 's|set(Protobuf_VERSION "4.22.3")|set(Protobuf_VERSION "v4.25.8")|g' CMakeLists.txt

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
python${PYTHON_VERSION} -m pip install cython meson
python${PYTHON_VERSION} -m pip install 'numpy==1.26.4'
python${PYTHON_VERSION} -m pip install parameterized
python${PYTHON_VERSION} -m pip install pytest nbval pythran mypy-protobuf
python${PYTHON_VERSION} -m pip install "scipy<1.14"
python${PYTHON_VERSION} -m pip install ml-dtypes  # required while running tests
python${PYTHON_VERSION} -m pip install wheel
python${PYTHON_VERSION} -m pip install build

# export CMAKE_ARGS="$CMAKE_ARGS -DPYTHON_EXECUTABLE=$(which python3.12)"
# Reason: In ONNX v1.18.0, setup.py uses a custom get_python_executable() which may resolve to /usr/bin/python3
# even in a Python 3.12 venv, causing incorrect CMake behavior. To ensure the correct Python is used, we explicitly set it.
# Also, since ONNX v1.18.0's install logic depends on this, we must build + install in the script directly.

export PYTHON_EXECUTABLE=$(which python)
export PYTHON_BIN=$(which python)
export PYTHON_INCLUDE=$(python -c "from sysconfig import get_paths as gp; print(gp()['include'])")
export PYTHON_LIB=$(python -c "import sysconfig; print(sysconfig.get_config_var('LIBDIR'))")

export CMAKE_ARGS="$CMAKE_ARGS \
 -DPython3_EXECUTABLE=$PYTHON_BIN \
 -DPython3_INCLUDE_DIR=$PYTHON_INCLUDE \
 -DPython3_LIBRARY=$PYTHON_LIB/libpython${PYTHON_VERSION}.so"



if !(python${PYTHON_VERSION} -m build --wheel --no-isolation --outdir="$CURRENT_DIR/"); then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

echo " ------------------------------------------ Onnx Wheel Creating ------------------------------------------ "
python${PYTHON_VERSION} setup.py bdist_wheel --dist-dir $CURRENT_DIR
echo " ------------------------------------------ Onnx Wheel Created Successfully ------------------------------------------ "

export LD_LIBRARY_PATH="$OpenBLASInstallPATH/lib:$LIBPROTO_INSTALL/lib64:$LD_LIBRARY_PATH"
python${PYTHON_VERSION} -m pip install "$CURRENT_DIR"/onnx-*.whl
# Skipping test due to missing 're2/stringpiece.h' header file. Even after attempting to manually build RE2, the required header file could not be found.
echo " ------------------------------------------ Onnx Testing ------------------------------------------ "
if ! pytest --ignore=onnx/test/reference_evaluator_backend_test.py --ignore=onnx/test/test_backend_reference.py --ignore=onnx/test/reference_evaluator_test.py; then
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
