#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package         : llama.cpp
# Version         : Release
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
PACKAGE_VERSION=${1:-master}
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


CURRENT_DIR=$(pwd)
SCRIPT_PATH=$(dirname "$(realpath "$0")")
###############################################################################
# Clone repository
###############################################################################

cd "$CURRENT_DIR"
rm -rf "$PACKAGE_NAME"
echo "Cloning llama.cpp..."
git clone "$PACKAGE_URL"
cd "$PACKAGE_NAME"
git fetch --tags

if [[ "$PACKAGE_VERSION" == "Release" ]]; then
    LLAMA_CPP_VERSION=$(git describe --tags --match "b*" --abbrev=0)
    echo "PACKAGE_VERSION is Release. Using latest build tag: $LLAMA_CPP_VERSION"
else
    LLAMA_CPP_VERSION="$PACKAGE_VERSION"
fi

echo "Checking out $LLAMA_CPP_VERSION"
git checkout "$LLAMA_CPP_VERSION"

###############################################################################
# Determine build number for wheel version
###############################################################################

if [[ "$LLAMA_CPP_VERSION" =~ ^b[0-9]+$ ]]; then
    BUILD_TAG="$LLAMA_CPP_VERSION"
else
    BUILD_TAG=$(git describe --tags --match "b*" --abbrev=0)
fi

WHEEL_VERSION="${BUILD_TAG#b}"

echo "Repository Version : $PACKAGE_VERSION"
echo "Build Tag          : $BUILD_TAG"
echo "Wheel Version      : 1.0+${WHEEL_VERSION}"

###############################################################################
# Build llama.cpp
###############################################################################

echo "Configuring CMake..."
cmake -B build_llama
echo "Building..."
cmake --build build_llama -j"$(nproc)"

echo
echo "Build completed successfully."
echo

###############################################################################
# Verify required binaries
###############################################################################

BUILD_DIR="$CURRENT_DIR/$PACKAGE_NAME/build_llama/bin"
REQUIRED_BINS=(
    llama-cli
    llama-server
    llama-bench
    llama-batched-bench
)
echo "Verifying generated binaries..."

for bin in "${REQUIRED_BINS[@]}"; do
    if [[ ! -f "$BUILD_DIR/$bin" ]]; then
        echo "ERROR: Missing binary $bin"
        exit 1
    fi
done

echo
echo "All required binaries generated successfully."

###############################################################################
# Create standalone packaging directory
###############################################################################

echo "========================================================="
echo "Creating standalone wheel package"
echo "========================================================="

cd "$CURRENT_DIR"

PKG_ROOT="$CURRENT_DIR/llama_cpp_pkg"
PKG_NAME="llama_cpp_python_package"

rm -rf "$PKG_ROOT"

mkdir -p "$PKG_ROOT/$PKG_NAME/bin"
mkdir -p "$PKG_ROOT/$PKG_NAME/lib"

###############################################################################
# Copy executables
###############################################################################

echo "Copying executables..."

BINARIES=(
    llama-cli
    llama-server
    llama-bench
    llama-batched-bench
)

for bin in "${BINARIES[@]}"; do
    cp "$BUILD_DIR/$bin" "$PKG_ROOT/$PKG_NAME/bin/"
    chmod +x "$PKG_ROOT/$PKG_NAME/bin/$bin"
done

###############################################################################
# Copy all shared libraries
###############################################################################

echo "Copying shared libraries..."

find "$BUILD_DIR" -maxdepth 1 \( -name "*.so" -o -name "*.so.*" \) \
    -exec cp -a {} "$PKG_ROOT/$PKG_NAME/lib/" \;

###############################################################################
# Package __init__.py
###############################################################################

cat > "$PKG_ROOT/$PKG_NAME/__init__.py" <<'EOF'
"""
Standalone llama.cpp binaries packaged as a Python wheel.
"""
EOF

###############################################################################
# Launcher module
###############################################################################

cat > "$PKG_ROOT/$PKG_NAME/launcher.py" <<'EOF'
import subprocess
from pathlib import Path
import sys

BIN_DIR = Path(__file__).parent / "bin"

def run(binary):
    exe = BIN_DIR / binary
    raise SystemExit(
        subprocess.call([str(exe)] + sys.argv[1:])
    )

def llama_cli():
    run("llama-cli")

def llama_server():
    run("llama-server")

def llama_bench():
    run("llama-bench")

def llama_batched_bench():
    run("llama-batched-bench")
EOF

###############################################################################
# setup.py
###############################################################################

cat > "$PKG_ROOT/setup.py" <<EOF
from setuptools import setup, find_packages

setup(
    name="llama_cpp_python_package",
    version="1.0+${WHEEL_VERSION}",
    description="Standalone llama.cpp binaries",
    author="Shalini Salomi Bodapati",
    author_email="Shalini.Salomi.Bodapati@ibm.com",

    packages=find_packages(),

    include_package_data=True,

    package_data={
        "llama_cpp_python_package": [
            "bin/*",
            "lib/*",
        ],
    },

    python_requires=">=3.8",

    zip_safe=False,

    entry_points={
        "console_scripts": [
            "llama-cli=llama_cpp_python_package.launcher:llama_cli",
            "llama-server=llama_cpp_python_package.launcher:llama_server",
            "llama-bench=llama_cpp_python_package.launcher:llama_bench",
            "llama-batched-bench=llama_cpp_python_package.launcher:llama_batched_bench",
        ],
    },
)
EOF

###############################################################################
# MANIFEST.in
###############################################################################

cat > "$PKG_ROOT/MANIFEST.in" <<EOF
recursive-include ${PKG_NAME}/bin *
recursive-include ${PKG_NAME}/lib *
EOF

###############################################################################
# Build wheel
###############################################################################

echo
echo "Building wheel..."
echo

echo "=============== Building wheel =================="
cd "$PKG_ROOT"
python -m pip install --upgrade pip setuptools wheel build

if ! python setup.py bdist_wheel --plat-name linux_ppc64le --dist-dir "$CURRENT_DIR/"; then
    echo "============ Wheel Creation Failed ================="
    EXIT_CODE=1
else
    echo "============ Wheel successfully built ================="
    ls -lh "$CURRENT_DIR"/*.whl
    echo "Wheel version:"
    echo "1.0+${WHEEL_VERSION}"
fi
