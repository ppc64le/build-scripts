#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package         : Ollama (Power10 optimized)
# Version         : v0.13.1
# Source repo     : https://github.com/ollama/ollama
# Tested on       : UBI:9.6
# Language        : Go, C, Python
# Ci-Check        : True
# Script License  : Apache License, Version 2 or later
# Maintainer      : Pratik Tonage <Pratik.Tonage@ibm.com>
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
PACKAGE_VERSION=${1:-v0.13.1}
PACKAGE_URL=https://github.com/ollama/ollama
OLLAMA_VERSION=${PACKAGE_VERSION}
CURRENT_DIR=$(pwd)
PACKAGE_DIR=ollama
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
# Download Go
# -----------------------------------------------------------------------------
GO_VERSION="1.24.1"
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
# Clone and patch Ollama
# -----------------------------------------------------------------------------

echo "**** Cloning Ollama repository..."
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

echo "** Downloading Power10 Patches..."
wget -O build_power.patch https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/ollama/build_power_v0.13.1.patch
wget -O set_threads_env.patch https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/ollama/set_threads_env_v0.13.1.patch
wget -O enable_mma.patch https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/ollama/enable_mma_v0.13.1.patch

echo "** Applying Patches..."
patch -p1 < build_power.patch
patch -p1 < set_threads_env.patch
patch -p1 < enable_mma.patch

# -----------------------------------------------------------------------------
# Build Ollama
# -----------------------------------------------------------------------------
echo "**** Building Ollama with CMake..."
cmake -B build
cmake --build build -j$(nproc)

export CGO_LDFLAGS="-L$(pwd)/build/lib/ollama/ -lggml-cpu-power10"

echo "**** Building Ollama binary with Go..."
../go/bin/go build --tags ppc64le.power10 -o ollama .

if ls ollama 1>/dev/null 2>&1; then
    echo "Ollama Binary built successfully:"
    ls ollama
else
    echo "Ollama Build failed"
    EXIT_CODE=1
fi

# -----------------------------------------------------------------------------
# Auto-generate setup.py and minimal package structure for wheel build
# -----------------------------------------------------------------------------
echo "**** Creating setup.py and package files ****"

PKG_NAME="ollama_python_package"
mkdir -p ${PKG_NAME} ${PKG_NAME}/bin ${PKG_NAME}/lib

# Generate setup.py
cat <<'EOF' > setup.py
from setuptools import setup, find_packages
from setuptools.command.build_py import build_py
import os, shutil, stat

PYTHON_PACKAGE_NAME = "ollama_python_package"
VERSION = "0.13.1"

BIN_SRC = os.path.join(os.getcwd(), "ollama")
LIB_SRC = os.path.join(os.getcwd(), "build", "lib", "ollama")
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
        if os.path.exists(BIN_SRC):
            print(f"Copying binary to {PKG_BIN_DIR}")
            shutil.copy2(BIN_SRC, PKG_BIN_DIR)
            make_executable(os.path.join(PKG_BIN_DIR, "ollama"))
        else:
            print("Warning: ollama binary not found")

        # Copy .so libraries
        if os.path.exists(LIB_SRC):
            for f in os.listdir(LIB_SRC):
                if f.endswith(".so"):
                    src = os.path.join(LIB_SRC, f)
                    dst = os.path.join(PKG_LIB_DIR, f)
                    print(f"Copying shared lib: {src}")
                    shutil.copy2(src, dst)
        else:
            print(f"Warning: {LIB_SRC} not found")

        super().run()

setup(
    name=PYTHON_PACKAGE_NAME,
    version=VERSION,
    author="Pratik Tonage",
    author_email="Pratik.Tonage@ibm.com",
    description="Power10 optimized Ollama binary + shared libs as Python package",
    license="MIT",
    packages=[PYTHON_PACKAGE_NAME],
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
    """Run embedded Ollama binary packaged with this wheel."""
    bin_path = Path(__file__).parent / "bin" / "ollama"
    if not bin_path.exists():
        raise FileNotFoundError("Embedded ollama binary not found.")
    subprocess.run([str(bin_path)] + (args or []))
EOF

echo "=============== Building wheel =================="
python -m pip install --upgrade pip setuptools wheel build

if ! python -m build --wheel --no-isolation --outdir="$CURRENT_DIR/"; then
    echo "============ Wheel Creation Failed ================="
    EXIT_CODE=1
else
    echo "============ Wheel successfully built ================="
fi

# -----------------------------------------------------------------------------
# Cleanup
# -----------------------------------------------------------------------------
cd ../..
echo "**** Cleaning temporary files..."
rm -f go1.24.1.linux-ppc64le.tar.gz
echo "**** Done! Ollama Power10 wheel ready."
