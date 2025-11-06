#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package         : Ollama (Power10 optimized)
# Version         : 0.1.0
# Source repo     : https://github.com/ollama/ollama
# Tested on       : UBI:9.6
# Language        : Go, C, Python
# Travis-Check    : True
# Script License  : Apache License, Version 2 or later
# Maintainer      : Shalini Salomi Bodapati <Shalini-Salomi-Bodapati@ibm.com>
#!/bin/bash
# -----------------------------------------------------------------------------


set -e

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
PKG_NAME="ollama_power"
PKG_VERSION="0.1.0"
PKG_DIR="ollama_wheel"


echo "------------------------Installing dependencies-------------------"

# install core dependencies
yum install -y python python-pip python-devel  gcc-toolset-13 gcc-toolset-13-binutils gcc-toolset-13-binutils-devel gcc-toolset-13-gcc-c++ git make cmake binutils wget patch

python -m pip install --upgrade pip wheel

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
git clone https://github.com/ollama/ollama.git

cd ollama

echo "**** Downloading Power10 patches..."
wget -q -O build_power.patch https://github.com/ollama/ollama/commit/67b8d3c817fbdc57fedad9b032d0efc10285220a.patch
wget -q -O set_threads_env.patch https://github.com/ollama/ollama/commit/1364a887a1d7c25522e9c921d55e50a6aea44964.patch
wget -q -O enable_mma.patch https://github.com/ollama/ollama/commit/fe924304809ae8e6bd6957b0ce5759eb2a796d42.patch

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

# -----------------------------------------------------------------------------
# Package the binary into a wheel
# -----------------------------------------------------------------------------
cd ..
echo "**** Packaging Ollama into Python wheel..."
rm -rf ${PKG_DIR}
mkdir -p ${PKG_DIR}/${PKG_NAME}/bin

# Copy built files
cp ollama/ollama ${PKG_DIR}/${PKG_NAME}/bin/
cp ollama/build/lib/ollama/*.so ${PKG_DIR}/${PKG_NAME}/bin/ || true

# -----------------------------------------------------------------------------
# Create Python wrapper
# -----------------------------------------------------------------------------
cat > ${PKG_DIR}/${PKG_NAME}/__init__.py << 'EOF'
from .cli import run_ollama
EOF

cat > ${PKG_DIR}/${PKG_NAME}/cli.py << 'EOF'
import subprocess
import sys
import os

def run_ollama(args=None):
    """Run Ollama binary from the packaged wheel."""
    base_dir = os.path.dirname(__file__)
    bin_path = os.path.join(base_dir, "bin", "ollama")

    if not os.path.exists(bin_path):
        raise FileNotFoundError(f"Ollama binary not found at {bin_path}")

    if args is None:
        args = sys.argv[1:]

    cmd = [bin_path] + args
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        print(result.stdout.strip())
    except subprocess.CalledProcessError as e:
        print(e.stderr, file=sys.stderr)
        sys.exit(e.returncode)
EOF

# -----------------------------------------------------------------------------
# Generate pyproject.toml
# -----------------------------------------------------------------------------
cat > ${PKG_DIR}/pyproject.toml << EOF
[build-system]
requires = ["setuptools", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "${PKG_NAME}"
version = "${PKG_VERSION}"
description = "Packaged Ollama binary with Power10-optimized libraries"
authors = [{ name = "IBM Power Team" }]
requires-python = ">=3.6"

[tool.setuptools]
include-package-data = true

[tool.setuptools.packages.find]
where = ["."]
namespaces = false

[tool.setuptools.package-data]
${PKG_NAME} = ["bin/ollama", "bin/*.so"]

[project.scripts]
ollama-power = "${PKG_NAME}.cli:run_ollama"
EOF

# -----------------------------------------------------------------------------
# Build the wheel
# -----------------------------------------------------------------------------
echo "**** Building Python wheel..."
cd ${PKG_DIR}
python -m build --wheel

echo "**** Wheel generated at: $(pwd)/dist/"
ls -lh dist/

# -----------------------------------------------------------------------------
# Cleanup
# -----------------------------------------------------------------------------
cd ../..
echo "**** Cleaning temporary files..."
rm -f go1.24.1.linux-ppc64le.tar.gz
echo "**** Done! Ollama Power10 wheel ready."

