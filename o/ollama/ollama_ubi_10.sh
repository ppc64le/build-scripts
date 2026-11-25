#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package         : Ollama (Power10 optimized)
# Version         : v0.40.11
# Source repo     : https://github.com/ollama/ollama
# Tested on       : UBI:10
# Language        : Go, C, Python
# Ci-Check        : True
# Script License  : Apache License, Version 2 or later
# Maintainer      : Shalini Salomi Bodapati <Shalini.Salomi.Bodapati@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -e

# Variables
PACKAGE_NAME=ollama
PACKAGE_VERSION=${1:-v0.40.11}
PACKAGE_URL=https://github.com/ollama/ollama
OLLAMA_VERSION=${PACKAGE_VERSION}
CURRENT_DIR=$(pwd)
PACKAGE_DIR=ollama
SCRIPT_PATH=$(dirname $(realpath $0))

echo "------------------------Installing dependencies-------------------"

# install core dependencies
yum install -y python python-pip python-devel gcc-toolset-15 gcc-toolset-15-binutils gcc-toolset-15-binutils-devel gcc-toolset-15-gcc-c++ gcc-toolset-15-gcc-gfortran git make cmake binutils wget patch tar gzip openssl-devel perl libatomic

python -m pip install --upgrade pip setuptools wheel build

export PATH=/opt/rh/gcc-toolset-15/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH
gcc --version

echo "**** Checking GCC version..."
gcc -v || true

# ----------------------------------------------------------------
# Download Go
# -----------------------------------------------------------------
GO_VERSION="1.26.1"
GO_TAR="go${GO_VERSION}.linux-ppc64le.tar.gz"
GO_DIR="go"

if [ ! -d "${GO_DIR}" ]; then
    echo "**** Downloading Go ${GO_VERSION}..."
    wget -q https://go.dev/dl/${GO_TAR}
    echo "**** Extracting Go binary..."
    tar xzf ${GO_TAR}
else
    echo "**** Go already extracted, skipping..."
fi

export PATH="$(pwd)/go/bin:$PATH"

# -----------------------------------------------------------------------------
# Build OpenBLAS with POWER10 optimizations
# -----------------------------------------------------------------------------
OPENBLAS_INSTALL_DIR="${CURRENT_DIR}/openblas_install"
if [ ! -f "${OPENBLAS_INSTALL_DIR}/lib/libopenblas.so" ]; then
    echo "**** Building OpenBLAS with POWER10 optimizations..."
    OPENBLAS_SRC_DIR="${CURRENT_DIR}/OpenBLAS"
    if [ ! -d "${OPENBLAS_SRC_DIR}" ]; then
        git clone --depth 1 --branch v0.3.34 https://github.com/OpenMathLib/OpenBLAS.git "${OPENBLAS_SRC_DIR}"
    fi
    pushd "${OPENBLAS_SRC_DIR}"
    make -j$(nproc) \
        TARGET=POWER10 \
        DYNAMIC_ARCH=0 \
        USE_OPENMP=1 \
        NUM_THREADS=64 \
        FC=/opt/rh/gcc-toolset-15/root/usr/bin/gfortran \
        CC=/opt/rh/gcc-toolset-15/root/usr/bin/gcc \
        COMMON_OPT="-O3 -mcpu=power10 -mtune=power10" \
        FCOMMON_OPT="-O3 -mcpu=power10 -mtune=power10" \
        EXTRALIB="-fopenmp"
    make PREFIX="${OPENBLAS_INSTALL_DIR}" install
    popd
fi

export PKG_CONFIG_PATH="${OPENBLAS_INSTALL_DIR}/lib/pkgconfig:$PKG_CONFIG_PATH"
export LD_LIBRARY_PATH="${OPENBLAS_INSTALL_DIR}/lib:$LD_LIBRARY_PATH"

# -----------------------------------------------------------------------------
# Clone and Build Ollama
# -----------------------------------------------------------------------------

echo "**** Cloning Ollama repository..."
if [ ! -d "${PACKAGE_NAME}" ]; then
    git clone $PACKAGE_URL
fi
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init --recursive

# -----------------------------------------------------------------------------
# Build llama-server and Ollama binary
# -----------------------------------------------------------------------------
echo "**** Building llama-server with CMake..."
export CGO_CFLAGS="-O3 -mcpu=power10 -mtune=power10 -maltivec -mvsx"
export CGO_CXXFLAGS="-O3 -mcpu=power10 -mtune=power10 -maltivec -mvsx"
export CGO_LDFLAGS="-L${OPENBLAS_INSTALL_DIR}/lib -lopenblas -lgfortran -lgomp -lm"

cmake -S llama/server -B build/llama-server \
    -DCMAKE_C_COMPILER=/opt/rh/gcc-toolset-15/root/usr/bin/gcc \
    -DCMAKE_CXX_COMPILER=/opt/rh/gcc-toolset-15/root/usr/bin/g++ \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS="-O3 -mcpu=power10 -mtune=power10 -maltivec -mvsx" \
    -DCMAKE_CXX_FLAGS="-O3 -mcpu=power10 -mtune=power10 -maltivec -mvsx" \
    -DCMAKE_EXE_LINKER_FLAGS="-lgfortran -lgomp -Wl,-rpath,'\$ORIGIN' -Wl,-rpath,'\$ORIGIN/..' -Wl,-rpath,'\$ORIGIN/../lib' -Wl,-rpath,'\$ORIGIN/../../lib' -Wl,-rpath,'\$ORIGIN/lib'" \
    -DGGML_BLAS=ON \
    -DGGML_BLAS_VENDOR=OpenBLAS \
    -DGGML_OPENMP=ON \
    -DBLAS_LIBRARIES="${OPENBLAS_INSTALL_DIR}/lib/libopenblas.so;-lgfortran;-lgomp" \
    -DBLAS_INCLUDE_DIRS="${OPENBLAS_INSTALL_DIR}/include" \
    -DGGML_NATIVE=OFF \
    -DGGML_CPU_ALL_VARIANTS=OFF \
    -DBUILD_SHARED_LIBS=OFF

cmake --build build/llama-server --config Release --target llama-server -j$(nproc)

echo "**** Building Ollama binary with Go..."
go generate ./...
go build -o ollama \
    -ldflags="-s -w -X github.com/ollama/ollama/version.Version=${PACKAGE_VERSION#v}" \
    -trimpath \
    .

if [ -f "ollama" ]; then
    echo "Ollama Binary built successfully:"
    ls -la ollama
else
    echo "Ollama Build failed"
    exit 1
fi

# -----------------------------------------------------------------------------
# Auto-generate setup.py and package structure for wheel build
# -----------------------------------------------------------------------------
echo "**** Creating setup.py and package files ****"

PKG_NAME="ollama_python_package"
mkdir -p ${PKG_NAME} ${PKG_NAME}/bin ${PKG_NAME}/lib ${PKG_NAME}/lib/ollama

# Generate setup.py
cat <<EOF > setup.py
from setuptools import setup, find_packages
from setuptools.command.build_py import build_py
import os, shutil, stat

PYTHON_PACKAGE_NAME = "ollama_python_package"
VERSION = "${PACKAGE_VERSION#v}"

BIN_SRC = os.path.join(os.getcwd(), "ollama")
LLAMA_SERVER_SRC = os.path.join(os.getcwd(), "build", "llama-server", "bin", "llama-server")
if not os.path.exists(LLAMA_SERVER_SRC):
    LLAMA_SERVER_SRC = os.path.join(os.getcwd(), "build", "llama-server", "llama-server")

OPENBLAS_LIB_SRC = "${OPENBLAS_INSTALL_DIR}/lib"
GCC_LIB_SRC = "/opt/rh/gcc-toolset-15/root/usr/lib64"
BUILD_LIB_SRC = os.path.join(os.getcwd(), "build", "lib", "ollama")

def make_executable(path):
    if os.path.exists(path):
        st = os.stat(path)
        os.chmod(path, st.st_mode | stat.S_IEXEC | stat.S_IXGRP | stat.S_IXOTH)

class CustomBuild(build_py):
    def run(self):
        pkg_bin = os.path.join(PYTHON_PACKAGE_NAME, "bin")
        pkg_lib = os.path.join(PYTHON_PACKAGE_NAME, "lib")
        pkg_lib_ollama = os.path.join(PYTHON_PACKAGE_NAME, "lib", "ollama")

        os.makedirs(pkg_bin, exist_ok=True)
        os.makedirs(pkg_lib, exist_ok=True)
        os.makedirs(pkg_lib_ollama, exist_ok=True)

        # Copy ollama binary
        if os.path.exists(BIN_SRC):
            print(f"Copying ollama binary to {pkg_bin}")
            shutil.copy2(BIN_SRC, pkg_bin)
            make_executable(os.path.join(pkg_bin, "ollama"))
        else:
            print("Warning: ollama binary not found")

        # Copy llama-server to lib/ollama, lib, and bin
        if os.path.exists(LLAMA_SERVER_SRC):
            for target_dir in [pkg_lib_ollama, pkg_lib, pkg_bin]:
                print(f"Copying llama-server to {target_dir}")
                shutil.copy2(LLAMA_SERVER_SRC, target_dir)
                make_executable(os.path.join(target_dir, "llama-server"))
        else:
            print("Warning: llama-server binary not found")

        # Copy shared libraries
        for src_dir in [OPENBLAS_LIB_SRC, GCC_LIB_SRC, BUILD_LIB_SRC]:
            if os.path.exists(src_dir):
                for f in os.listdir(src_dir):
                    if ".so" in f and any(k in f for k in ["openblas", "gfortran", "gomp", "ggml", "llama"]):
                        src = os.path.join(src_dir, f)
                        if os.path.isfile(src):
                            shutil.copy2(src, pkg_lib)
                            shutil.copy2(src, pkg_lib_ollama)

        super().run()

setup(
    name=PYTHON_PACKAGE_NAME,
    version=VERSION,
    author="Shalini Salomi Bodapati",
    author_email="Shalini.Salomi.Bodapati@ibm.com",
    description="Power10 optimized Ollama binary + shared libs as Python package",
    license="MIT",
    packages=find_packages(include=["ollama_python_package*"]),
    include_package_data=True,
    cmdclass={'build_py': CustomBuild},
    package_data={
        PYTHON_PACKAGE_NAME: [
            "bin/*",
            "lib/*",
            "lib/ollama/*",
        ]
    },
    python_requires=">=3.8",
)
EOF

# Create __init__.py (wrapper)
cat <<'EOF' > ${PKG_NAME}/__init__.py
import subprocess
import os
from pathlib import Path

def run(args=None):
    """Run embedded Ollama binary packaged with this wheel."""
    bin_path = Path(__file__).parent / "bin" / "ollama"
    if not bin_path.exists():
        raise FileNotFoundError("Embedded ollama binary not found.")
    pkg_dir = Path(__file__).parent
    lib_dirs = [
        str(pkg_dir / "lib"),
        str(pkg_dir / "lib" / "ollama"),
    ]
    env = os.environ.copy()
    current_ld = env.get("LD_LIBRARY_PATH", "")
    env["LD_LIBRARY_PATH"] = ":".join(lib_dirs + ([current_ld] if current_ld else []))
    return subprocess.run([str(bin_path)] + (args or []), env=env)
EOF

echo "=============== Building wheel =================="
python -m pip install --upgrade pip setuptools wheel build

if ! python setup.py bdist_wheel --plat-name linux_ppc64le --dist-dir "$CURRENT_DIR/"; then
    echo "============ Wheel Creation Failed ================="
    EXIT_CODE=1
else
    echo "============ Wheel successfully built ================="
fi
