#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package         : llama.cpp
# Version         : latest release TAG from master branch)
# Source repo     : https://github.com/ggml-org/llama.cpp
# Tested on       : UBI:9.6
# Language        : C, C++
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
PACKAGE_NAME=llama.cpp
PACKAGE_URL=https://github.com/ggml-org/llama.cpp
BRANCH=master
CURRENT_DIR=$(pwd)
PACKAGE_DIR=llama.cpp
SCRIPT_PATH=$(dirname $(realpath $0))

echo "------------------------Installing dependencies-------------------"

# install core dependencies
yum install -y python python-pip python-devel  gcc-toolset-13 gcc-toolset-13-binutils gcc-toolset-13-binutils-devel gcc-toolset-13-gcc-c++ git make cmake binutils wget patch

python -m pip install --upgrade pip setuptools wheel build

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
gcc --version

echo "**** Checking GCC version..."
gcc -v || true

# -----------------------------------------------------------------------------
# Clone latest llama.cpp 
# -----------------------------------------------------------------------------

echo "**** Cloning llama.cpp repository..."
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $BRANCH
git fetch --tags

PACKAGE_VERSION=$(git describe --tags --abbrev=0)

echo "Building llama.cpp version: ${PACKAGE_VERSION}"

# -----------------------------------------------------------------------------
# Build llama.cpp
# -----------------------------------------------------------------------------
cmake -B build_llama
if ! cmake --build build_llama -j$(nproc); then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    exit 1
fi


# -----------------------------------------------------------------------------
# Auto-generate setup.py and minimal package structure for wheel build
# -----------------------------------------------------------------------------
echo "**** Creating setup.py and package files ****"

# Generate setup.py
cat <<EOF > setup.py
from setuptools import setup, find_packages
from setuptools.command.build_py import build_py
import os, shutil, stat

PYTHON_PACKAGE_NAME = "llama_cpp_python_package"
VERSION = "${PACKAGE_VERSION}"
PKG_NAME = "llama_cpp_python_package"
mkdir -p ${PKG_NAME} ${PKG_NAME}/bin ${PKG_NAME}/lib

BUILD_DIR = os.path.join(os.getcwd(), "build_llama", "bin")

BINARIES = [
    "llama-cli",
    "llama-server",
    "llama-bench",
    "llama-batched-bench",
]

LIBRARIES = [
    "libllama-bench-impl.so",
    "libllama-common.so.0",
    "libllama.so.0",
    "libggml.so.0",
    "libggml-cpu.so.0",
    "libggml-base.so.0",
]

PKG_BIN_DIR = os.path.join(PYTHON_PACKAGE_NAME, "bin")
PKG_LIB_DIR = os.path.join(PYTHON_PACKAGE_NAME, "lib")

def make_executable(path):
    st = os.stat(path)
    os.chmod(path, st.st_mode | stat.S_IEXEC)

class CustomBuild(build_py):
    def run(self):
        os.makedirs(PKG_BIN_DIR, exist_ok=True)
        os.makedirs(PKG_LIB_DIR, exist_ok=True)

        # Copy ollama binary
        if os.path.exists(BUILD_DIR):
            print(f"Copying binaries to {PKG_BIN_DIR}")
            for binary in BINARIES:
                src = os.path.join(BUILD_DIR, binary)

                if not os.path.exists(src):
                    print(f"Warning: {src} not found")
                    continue

                dst = os.path.join(PKG_BIN_DIR, binary)
                shutil.copy2(src, dst)
                make_executable(dst)
        else:
            print("Warning: llama.cpp binaries not found")

        # Copy .so libraries
        if os.path.exists(BUILD_DIR):
            for lib in LIBRARIES:
                src = os.path.join(BUILD_DIR, lib)

                if os.path.exists(src):
                   shutil.copy2(src, os.path.join(PKG_LIB_DIR, lib))
        else:
            print(f"Warning: {lib} not found")
            
        super().run()

setup(
    name=PYTHON_PACKAGE_NAME,
    version=VERSION,
    author="Shalini Salomi Bodapati",
    author_email="Shalini.Salomi.Bodapati@ibm.com",
    description="llama.cpp binaries + shared libs as Python package",
    license="MIT",
    packages=find_packages(include=["llama_cpp_python_package"]),
    include_package_data=False,
    cmdclass={'build_py': CustomBuild},
    package_data={PYTHON_PACKAGE_NAME: ["bin/*", "lib/*.so"]},
    python_requires=">=3.8",
)
EOF

# Create __init__.py (wrapper)
cat <<'EOF' > ${PKG_NAME}/__init__.py
import subprocess
from pathlib import Path

def run(args=None):
    """Run llama-cli packaged with this wheel."""
    bin_path = Path(__file__).parent / "bin" / "llama-cli"
    if not bin_path.exists():
        raise FileNotFoundError("llama-cli binary not found.")
    subprocess.run([str(bin_path)] + (args or []))
EOF

echo "=============== Building wheel =================="
python -m pip install --upgrade pip setuptools wheel build

if ! python setup.py bdist_wheel --plat-name linux_ppc64le --dist-dir "$CURRENT_DIR/"; then
    echo "============ Wheel Creation Failed ================="
    EXIT_CODE=1
else
    echo "============ Wheel successfully built ================="
fi
