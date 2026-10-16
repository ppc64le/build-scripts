#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : numba
# Version       : 0.65.1
# Source repo   : https://github.com/numba/numba
# Tested on     : UBI 10.2
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=numba
PACKAGE_VERSION=${1:-"0.65.1"}
PYTHON_VERSION=${2:-"3.12"}
PACKAGE_URL=https://github.com/numba/numba
PACKAGE_DIR=numba
WORKING_DIR=$(pwd)
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

LLVMLITE_VERSION="v0.47.0"
LLVM_VERSION="20.1.8"
LLVM_TAG="llvmorg-${LLVM_VERSION}"
LLVM_PREFIX="${LLVM_PREFIX:-"/opt/llvm-${LLVM_VERSION}"}"
NUMPY_VERSION=">=2.0.0,<2.5"

if [ -z "${CPU_FLAGS+x}" ]; then
    if grep -q "POWER10" /proc/cpuinfo 2>/dev/null; then
        CPU_FLAGS="-mcpu=power10 -mtune=power10"
        echo "Detected POWER10 — applying power10 optimization flags"
    else
        CPU_FLAGS=""
        echo "POWER10 not detected — no arch-specific flags applied"
    fi
else
    echo "Using caller supplied CPU_FLAGS='${CPU_FLAGS}'"
fi

yum install -y wget git cmake ninja-build make gcc gcc-c++ \
    libffi-devel openssl-devel bzip2-devel xz-devel zlib-devel \
    "python${PYTHON_VERSION}" "python${PYTHON_VERSION}-devel" "python${PYTHON_VERSION}-pip" || true

gcc --version
g++ --version

export CFLAGS="${CPU_FLAGS}"
export CXXFLAGS="${CPU_FLAGS}"

PYTHON_CMD=$(command -v "python${PYTHON_VERSION}" || command -v python3 || command -v python || true)
if [ -z "$PYTHON_CMD" ]; then
    echo "ERROR: No Python interpreter found. Please install Python >= 3.12."
    exit 1
fi

PYTHON_SHORT=$("$PYTHON_CMD" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
echo "Using Python ${PYTHON_SHORT} (${PYTHON_CMD})"

"$PYTHON_CMD" -c "import sys; assert sys.version_info >= (3, 12), f'Python >= 3.12 required for numba ${PACKAGE_VERSION}, found {sys.version}'"

"$PYTHON_CMD" -m pip install --upgrade pip
"$PYTHON_CMD" -m pip install setuptools wheel build
# NumPy's Meson build manages per-ISA -mcpu flags internally; a global -mcpu
# via CFLAGS/CXXFLAGS conflicts with its VSX2 dispatch units and breaks the build.
(unset CFLAGS CXXFLAGS; "$PYTHON_CMD" -m pip install "numpy${NUMPY_VERSION}")

# -----------------------------------------------------------------------------
# Install LLVM
# -----------------------------------------------------------------------------
echo "-------------------Installing LLVM ${LLVM_VERSION}----------------------"

if [ -f "${LLVM_PREFIX}/lib64/cmake/llvm/LLVMConfig.cmake" ] || \
   [ -f "${LLVM_PREFIX}/lib/cmake/llvm/LLVMConfig.cmake" ]; then
    echo "LLVM ${LLVM_VERSION} already present in ${LLVM_PREFIX} — reusing"
else
    echo "Building LLVM ${LLVM_VERSION} ..."
    rm -rf llvm-project
    if ! git clone --depth 1 --branch ${LLVM_TAG} https://github.com/llvm/llvm-project llvm-project; then
        echo "------------------llvm-project:clone_fails---------------------------------------"
        echo "llvm-project | https://github.com/llvm/llvm-project | ${LLVM_TAG} | $OS_NAME | GitHub | Fail | Clone_Fails"
        exit 1
    fi
    cd llvm-project
    mkdir build && cd build

    cmake \
        -DCMAKE_INSTALL_PREFIX="${LLVM_PREFIX}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DLLVM_TARGETS_TO_BUILD="PowerPC" \
        -DCMAKE_C_FLAGS="${CPU_FLAGS}" \
        -DCMAKE_CXX_FLAGS="${CPU_FLAGS}" \
        -DLLVM_ENABLE_RTTI=ON \
        -DLLVM_ENABLE_LIBEDIT=OFF \
        -DLLVM_ENABLE_LIBXML2=OFF \
        -DLLVM_ENABLE_TERMINFO=OFF \
        -DLLVM_ENABLE_Z3_SOLVER=OFF \
        -DLLVM_ENABLE_ZLIB=OFF \
        -DLLVM_ENABLE_ZSTD=OFF \
        -DLLVM_INCLUDE_BENCHMARKS=OFF \
        -DLLVM_INCLUDE_DOCS=OFF \
        -DLLVM_INCLUDE_EXAMPLES=OFF \
        -DLLVM_INCLUDE_TESTS=OFF \
        -DLLVM_OPTIMIZED_TABLEGEN=ON \
        -GNinja \
        ../llvm

    echo "Building LLVM with $(nproc) jobs..."
    ninja -j"$(nproc)"
    ninja install

    cd "$WORKING_DIR"
    rm -rf llvm-project
fi

export CMAKE_PREFIX_PATH="${LLVM_PREFIX}${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"
export PATH="${LLVM_PREFIX}/bin:$PATH"
export LLVM_CONFIG="${LLVM_PREFIX}/bin/llvm-config"
llvm-config --version

echo "-------------------LLVM ${LLVM_VERSION} installation completed----------------------"

# -----------------------------------------------------------------------------
# Build llvmlite wheel
# -----------------------------------------------------------------------------
echo "-------------------Building llvmlite ${LLVMLITE_VERSION} wheel----------------------"

rm -rf llvmlite
if ! git clone --depth 1 --branch ${LLVMLITE_VERSION} https://github.com/numba/llvmlite llvmlite; then
    echo "------------------llvmlite:clone_fails---------------------------------------"
    echo "llvmlite | https://github.com/numba/llvmlite | ${LLVMLITE_VERSION} | $OS_NAME | GitHub | Fail | Clone_Fails"
    exit 1
fi
cd llvmlite
if ! "$PYTHON_CMD" -m build --wheel --no-isolation; then
    echo "------------------llvmlite:build_fails---------------------------------------"
    echo "llvmlite | https://github.com/numba/llvmlite | ${LLVMLITE_VERSION} | $OS_NAME | GitHub | Fail | Build_Fails"
    exit 1
fi
cd "$WORKING_DIR"

echo "-------------------llvmlite wheel built successfully----------------------"

# -----------------------------------------------------------------------------
# Build numba wheel
# -----------------------------------------------------------------------------
echo "-------------------Building numba ${PACKAGE_VERSION} wheel----------------------"

rm -rf "$PACKAGE_DIR"
if ! git clone --depth 1 --branch "$PACKAGE_VERSION" "$PACKAGE_URL" "$PACKAGE_DIR"; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Clone_Fails"
    exit 1
fi

cd "$PACKAGE_DIR"
if ! "$PYTHON_CMD" -m build --wheel --no-isolation; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Build_Fails"
    exit 1
fi
cd "$WORKING_DIR"

echo "-------------------numba wheel built successfully----------------------"

# -----------------------------------------------------------------------------
# Install and test in isolated virtual environment
# -----------------------------------------------------------------------------
echo "-------------------Installing and testing numba----------------------"

VENV_DIR="$WORKING_DIR/test_env"
rm -rf "$VENV_DIR"
"$PYTHON_CMD" -m venv "$VENV_DIR"
VENV_PYTHON="$VENV_DIR/bin/python3"
"$VENV_PYTHON" -m pip install --upgrade pip

# Same NumPy CFLAGS/CXXFLAGS guard as above.
if ! (unset CFLAGS CXXFLAGS; "$VENV_DIR/bin/pip" install \
        "$WORKING_DIR/llvmlite"/dist/*.whl \
        "$WORKING_DIR/$PACKAGE_DIR"/dist/*.whl \
        "numpy${NUMPY_VERSION}"); then
    echo "------------------$PACKAGE_NAME:install_fails---------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

if ! "$VENV_PYTHON" <<EOF
import numpy as np
import numba
import llvmlite
import llvmlite.binding as llvm

print("Python version:", __import__("sys").version.split()[0])
print("Numba version:", numba.__version__)
print("llvmlite version:", llvmlite.__version__)
print("LLVM version:", ".".join(map(str, llvm.llvm_version_info)))
print("NumPy version:", np.__version__)

assert numba.__version__ == "${PACKAGE_VERSION}", numba.__version__
assert llvm.llvm_version_info[0] == 20, llvm.llvm_version_info

default_triple = llvm.get_default_triple()
print("Default triple:", default_triple)
assert "powerpc64le" in default_triple, f"Unexpected triple: {default_triple}"
print("PowerPC64LE target: OK")

from numba import njit

@njit
def add(a, b):
    return a + b

@njit
def total(arr):
    s = 0.0
    for x in arr:
        s += x
    return s

assert add(2, 3) == 5
assert total(np.arange(1000, dtype=np.float64)) == 499500.0
print("Numba JIT OK")
EOF
then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 2
fi

echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
exit 0
