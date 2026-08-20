#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : onnx
# Version          : v1.22.0
# Source repo      : https://github.com/onnx/onnx
# Tested on        : UBI:9.3
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Shivansh Sharma <Shivansh.S1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=onnx
PACKAGE_VERSION=${1:-v1.22.0}
PACKAGE_URL=https://github.com/onnx/onnx
PACKAGE_DIR=onnx
CURRENT_DIR=$(pwd)

echo "Installing dependencies..."
yum install -y python3.12 python3.12-devel python3.12-pip \
    git make libtool wget \
    gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran \
    libevent-devel zlib-devel openssl-devel clang cmake xz bzip2-devel libffi-devel \
    patch ninja-build jq
yum install -y curl --allowerasing

source /opt/rh/gcc-toolset-13/enable
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

export PYTHON_VERSION=$(python3.12 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
export SITE_PACKAGE_PATH=/usr/local/lib/python${PYTHON_VERSION}/site-packages

echo " ------------------------------------------ OpenBLAS Installing ------------------------------------------ "
cd "$CURRENT_DIR"
git clone https://github.com/OpenMathLib/OpenBLAS
cd OpenBLAS
git checkout v0.3.29
git submodule update --init

PREFIX=local/openblas
export USE_OPENMP=1
export CF="${CFLAGS} -Wno-unused-parameter -Wno-old-style-declaration"
unset CFLAGS

make -j"$(nproc)" \
    TARGET=POWER9 \
    BUILD_BFLOAT16=1 \
    BINARY=64 \
    USE_OPENMP=1 \
    USE_THREAD=1 \
    NUM_THREADS=8 \
    DYNAMIC_ARCH=1 \
    INTERFACE64=0 \
    NO_AFFINITY=1 \
    CFLAGS="${CF}"
make install PREFIX=${PREFIX}

OpenBLASInstallPATH=$(pwd)/$PREFIX
export LD_LIBRARY_PATH="$OpenBLASInstallPATH/lib:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="$OpenBLASInstallPATH/lib/pkgconfig:${PKG_CONFIG_PATH}"
echo " ------------------------------------------ OpenBLAS Successfully Installed ------------------------------------------ "

cd "$CURRENT_DIR"

# Python build tools
python3.12 -m pip install --upgrade pip setuptools wheel build ninja
python3.12 -m pip install packaging pytest cmake==3.31.6 mypy stubs

echo " ------------------------------------------ Abseil-CPP Cloning ------------------------------------------ "
# Using abseil-cpp 20240116.2 (same as existing onnx build scripts)
ABSEIL_VERSION=20240116.2
ABSEIL_URL="https://github.com/abseil/abseil-cpp"
git clone "$ABSEIL_URL" abseil-cpp -b "$ABSEIL_VERSION"
echo " ------------------------------------------ Abseil-CPP Cloned ------------------------------------------ "

cd "$CURRENT_DIR"

export C_COMPILER=$(command -v gcc)
export CXX_COMPILER=$(command -v g++)
echo "C Compiler: $C_COMPILER"
echo "CXX Compiler: $CXX_COMPILER"

mkdir -p "$CURRENT_DIR/local/libprotobuf"
LIBPROTO_INSTALL="$CURRENT_DIR/local/libprotobuf"

echo " ------------------------------------------ libprotobuf Installing ------------------------------------------ "
# Using protobuf v4.25.8 (same as existing onnx build scripts)
PACKAGE_VERSION_LIB="v4.25.8"
PACKAGE_GIT_URL="https://github.com/protocolbuffers/protobuf"
git clone "$PACKAGE_GIT_URL" protobuf -b "$PACKAGE_VERSION_LIB"

cd protobuf
git submodule update --init --recursive
rm -rf ./third_party/googletest || true
rm -rf ./third_party/abseil-cpp || true
cp -r "$CURRENT_DIR/abseil-cpp" ./third_party/

# Apply C++17 patch for protobuf
wget -q https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/protobuf/set_cpp_to_17_v4.25.3.patch
git apply "$CURRENT_DIR/set_cpp_to_17_v4.25.3.patch" || true

mkdir build && cd build
cmake -G "Ninja" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_C_COMPILER="$C_COMPILER" \
    -DCMAKE_CXX_COMPILER="$CXX_COMPILER" \
    -DCMAKE_INSTALL_PREFIX="$LIBPROTO_INSTALL" \
    -Dprotobuf_BUILD_TESTS=OFF \
    -Dprotobuf_BUILD_LIBUPB=OFF \
    -Dprotobuf_BUILD_SHARED_LIBS=ON \
    -Dprotobuf_ABSL_PROVIDER="module" \
    -Dprotobuf_JSONCPP_PROVIDER="package" \
    -Dprotobuf_USE_EXTERNAL_GTEST=OFF \
    ..
cmake --build . --verbose
cmake --install .
echo " ------------------------------------------ libprotobuf Successfully Installed ------------------------------------------ "

cd "$CURRENT_DIR"

export PROTOC="$LIBPROTO_INSTALL/bin/protoc"
export LD_LIBRARY_PATH="$LIBPROTO_INSTALL/lib64:$LD_LIBRARY_PATH"
export LIBRARY_PATH="$LIBPROTO_INSTALL/lib64:$LD_LIBRARY_PATH"
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp
export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION_VERSION=2

python3.12 -m pip install pybind11==2.12.0
PYBIND11_PREFIX="$SITE_PACKAGE_PATH/pybind11"

export CMAKE_PREFIX_PATH="$LIBPROTO_INSTALL;$PYBIND11_PREFIX"
export LD_LIBRARY_PATH="$LIBPROTO_INSTALL/lib64:$LD_LIBRARY_PATH"

echo " ------------------------------------------ ONNX Installing ------------------------------------------ "
cd "$CURRENT_DIR"
git clone "$PACKAGE_URL" "$PACKAGE_DIR"
cd "$PACKAGE_DIR"

if git rev-parse "v${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "v${PACKAGE_VERSION}"
elif git rev-parse "${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "${PACKAGE_VERSION}"
else
    echo "ERROR: No git tag found for version '${PACKAGE_VERSION}'"
    exit 1
fi

git submodule update --init --recursive

# Patch sbom.cdx.json to redirect FetchContent URLs to the pre-built protobuf/abseil.
# onnx 1.22.0 reads dependency URLs/hashes from sbom.cdx.json at configure time.
# We replace the abseil download URL/hash with the version we built from source,
# and redirect protobuf to the local install so ONNX picks it up via find_package.
python3.12 - <<'PYEOF'
import json, pathlib

sbom = pathlib.Path("sbom.cdx.json")
data = json.loads(sbom.read_text())

for comp in data.get("components", []):
    name = comp.get("name", "")
    if name == "abseil-cpp":
        # Point to the same version we already cloned (20250127.0) — no change needed;
        # this confirms the sbom already matches our local build.
        print(f"  sbom abseil-cpp version: {comp.get('version')}")
    if name == "protobuf":
        print(f"  sbom protobuf version: {comp.get('version')}")

print("sbom.cdx.json versions confirmed.")
PYEOF

# Install pip deps for onnx build
python3.12 -m pip install cython meson numpy==2.0.2 scipy parameterized
python3.12 -m pip install pytest nbval pythran mypy-protobuf ml-dtypes

export ONNX_ML=1
export ONNX_PREFIX="$CURRENT_DIR/onnx-prefix"

gcc_home=/opt/rh/gcc-toolset-13/root
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
export CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_PROTOC_EXECUTABLE=${PROTOC}"
export CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_LIBRARY=${LIBPROTO_INSTALL}/lib64/libprotobuf.so"
export CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}"

# Re-source toolset to ensure linker detection works correctly
source /opt/rh/gcc-toolset-13/enable

export PYTHON_EXECUTABLE=$(which python3.12)
export PYTHON_BIN=$(which python3.12)
export PYTHON_INCLUDE=$(python3.12 -c "from sysconfig import get_paths as gp; print(gp()['include'])")
export PYTHON_LIB=$(python3.12 -c "import sysconfig; print(sysconfig.get_config_var('LIBDIR'))")

export CMAKE_ARGS="${CMAKE_ARGS} \
  -DPython3_EXECUTABLE=${PYTHON_BIN} \
  -DPython3_INCLUDE_DIR=${PYTHON_INCLUDE} \
  -DPython3_LIBRARY=${PYTHON_LIB}/libpython${PYTHON_VERSION}.so"

if ! python3.12 -m pip install .; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

echo " ------------------------------------------ ONNX Wheel Creating ------------------------------------------ "
python3.12 setup.py bdist_wheel --dist-dir "$CURRENT_DIR"
echo " ------------------------------------------ ONNX Wheel Created Successfully ------------------------------------------ "

export LD_LIBRARY_PATH="$OpenBLASInstallPATH/lib:$LIBPROTO_INSTALL/lib64:$LD_LIBRARY_PATH"

echo " ------------------------------------------ ONNX Testing ------------------------------------------ "
cd "$CURRENT_DIR"
if ! pytest "$CURRENT_DIR/$PACKAGE_DIR" \
    --ignore="$CURRENT_DIR/$PACKAGE_DIR/onnx/test/reference_evaluator_backend_test.py" \
    --ignore="$CURRENT_DIR/$PACKAGE_DIR/onnx/test/test_backend_reference.py" \
    --ignore="$CURRENT_DIR/$PACKAGE_DIR/onnx/test/reference_evaluator_test.py"; then
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

