#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : ollama
# Version       : v0.12.10
# Source repo   : https://github.com/ollama/ollama
# Tested on     : UBI:9.6
# Language      : Go
# Script License: Apache License, Version 2 or later
# Maintainer    : Shalini Salomi Bodapati <Shalini-Salomi-Bodapati@ibm.com>
# -----------------------------------------------------------------------------
# Auto-migrated (fixed) script - REVIEW REQUIRED
#   - Original: ollama_v0.12.10_ubi_9.6.sh
#   - Has patch commands
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="ollama"
PACKAGE_VERSION="${1:-v0.12.10}"
PACKAGE_URL="https://github.com/ollama/ollama"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="binutils cmake gcc-toolset-13 gcc-toolset-13-binutils gcc-toolset-13-binutils-devel gcc-toolset-13-gcc-c++ git make patch python python-devel python-pip wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# OPTIONAL: Custom environment variables (from original script)
# =============================================================================
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
export CGO_LDFLAGS="-L$(pwd)/build/lib/ollama/ -lggml-cpu-power10"

# =============================================================================
# OPTIONAL: Callback functions for custom logic
# =============================================================================

# Apply patches after cloning (extracted from original script)
post_clone() {
    # TODO: Review and update patch commands from original script
    # yum/dnf install moved to RH_DEP_PKGS

python -m pip install --upgrade pip setuptools wheel build
    wget -q -O build_power.patch https://github.com/ollama/ollama/commit/67b8d3c817fbdc57fedad9b032d0efc10285220a.patch
wget -q -O set_threads_env.patch https://github.com/ollama/ollama/commit/1364a887a1d7c25522e9c921d55e50a6aea44964.patch
    wget -q -O enable_mma.patch https://github.com/ollama/ollama/commit/fe924304809ae8e6bd6957b0ce5759eb2a796d42.patch

echo "** Applying Patches..."
    patch -p1 < build_power.patch
patch -p1 < set_threads_env.patch
    patch -p1 < enable_mma.patch

# -----------------------------------------------------------------------------
}

# REVIEW - following code was not auto-migrated. See PORTING-NOTES.md for details.
# OLLAMA_VERSION=${PACKAGE_VERSION}
# CURRENT_DIR=$(pwd)
# PACKAGE_DIR=ollama
# python -m pip install --upgrade pip setuptools wheel build
# export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
# export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
# gcc --version
# echo "**** Checking GCC version..."
# gcc -v || true
# GO_VERSION="1.24.1"
# GO_TAR="go${GO_VERSION}.linux-ppc64le.tar.gz"
# GO_DIR="go"
# if [ ! -d "${GO_DIR}" ]; then
#     echo "**** Downloading Go ${GO_VERSION}..."
#     wget -q https://go.dev/dl/${GO_TAR}
#     echo "**** Extracting Go binary..."
#     tar xzf ${GO_TAR}
#     echo "**** Go already extracted, skipping..."
# export PATH="$(pwd)/go/bin:$PATH"
# echo "**** Cloning Ollama repository..."
# echo "**** Downloading Power10 patches..."
# wget -q -O build_power.patch https://github.com/ollama/ollama/commit/67b8d3c817fbdc57fedad9b032d0efc10285220a.patch
# wget -q -O set_threads_env.patch https://github.com/ollama/ollama/commit/1364a887a1d7c25522e9c921d55e50a6aea44964.patch
# wget -q -O enable_mma.patch https://github.com/ollama/ollama/commit/fe924304809ae8e6bd6957b0ce5759eb2a796d42.patch
# echo "** Applying Patches..."
# patch -p1 < build_power.patch
# patch -p1 < set_threads_env.patch
# patch -p1 < enable_mma.patch
# echo "**** Building Ollama with CMake..."
# cmake -B build
# cmake --build build -j$(nproc)
# export CGO_LDFLAGS="-L$(pwd)/build/lib/ollama/ -lggml-cpu-power10"
# echo "**** Building Ollama binary with Go..."
# ../go/bin/go build --tags ppc64le.power10 -o ollama .
# if ls ollama 1>/dev/null 2>&1; then
#     echo "Ollama Binary built successfully:"
#     ls ollama
#     echo "Ollama Build failed"
#     EXIT_CODE=1
# echo "**** Creating setup.py and package files ****"
# PKG_NAME="ollama_python_package"
# mkdir -p ${PKG_NAME} ${PKG_NAME}/bin ${PKG_NAME}/lib
# cat <<'EOF' > setup.py
# from setuptools import setup, find_packages
# from setuptools.command.build_py import build_py
# import os, shutil, stat
# PYTHON_PACKAGE_NAME = "ollama_python_package"
# VERSION = "0.12.10"
# BIN_SRC = os.path.join(os.getcwd(), "ollama")
# LIB_SRC = os.path.join(os.getcwd(), "build", "lib", "ollama")
# PKG_BIN_DIR = os.path.join(PYTHON_PACKAGE_NAME, "bin")
# PKG_LIB_DIR = os.path.join(PYTHON_PACKAGE_NAME, "lib")
# def make_executable(path):
#     st = os.stat(path)
#     os.chmod(path, st.st_mode | stat.S_IEXEC)
# class CustomBuild(build_py):
#     def run(self):
#         os.makedirs(PKG_BIN_DIR, exist_ok=True)
#         os.makedirs(PKG_LIB_DIR, exist_ok=True)
#         if os.path.exists(BIN_SRC):
#             print(f"Copying binary to {PKG_BIN_DIR}")
#             shutil.copy2(BIN_SRC, PKG_BIN_DIR)
#             make_executable(os.path.join(PKG_BIN_DIR, "ollama"))
#         else:
#             print("Warning: ollama binary not found")
#         if os.path.exists(LIB_SRC):
#             for f in os.listdir(LIB_SRC):
#                 if f.endswith(".so"):
#                     src = os.path.join(LIB_SRC, f)
#                     dst = os.path.join(PKG_LIB_DIR, f)
#                     print(f"Copying shared lib: {src}")
#                     shutil.copy2(src, dst)
#         else:
#             print(f"Warning: {LIB_SRC} not found")
#         super().run()
# setup(
#     name=PYTHON_PACKAGE_NAME,
#     version=VERSION,
#     author="Shalini Salomi Bodapati",
#     author_email="Shalini-Salomi-Bodapati@ibm.com",
#     description="Power10 optimized Ollama binary + shared libs as Python package",
#     license="MIT",
#     packages=[PYTHON_PACKAGE_NAME],
#     include_package_data=False,
#     cmdclass={'build_py': CustomBuild},
#     package_data={PYTHON_PACKAGE_NAME: ["bin/*", "lib/*.so"]},
#     python_requires=">=3.8",
# )
# EOF
# cat <<'EOF' > ${PKG_NAME}/__init__.py
# import subprocess
# from pathlib import Path
# def run(args=None):
#     """Run embedded Ollama binary packaged with this wheel."""
#     bin_path = Path(__file__).parent / "bin" / "ollama"
#     if not bin_path.exists():
#         raise FileNotFoundError("Embedded ollama binary not found.")
#     subprocess.run([str(bin_path)] + (args or []))
# EOF
# echo "=============== Building wheel =================="
# python -m pip install --upgrade pip setuptools wheel build
#     echo "============ Wheel Creation Failed ================="
#     EXIT_CODE=1
#     echo "============ Wheel successfully built ================="
# cd ../..
# echo "**** Cleaning temporary files..."
# rm -f go1.24.1.linux-ppc64le.tar.gz
# echo "**** Done! Ollama Power10 wheel ready."

# =============================================================================
# Execute the build (invokes the Go template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/go.sh"
