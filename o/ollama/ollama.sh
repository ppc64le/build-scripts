#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : ollama
# Version       : v0.33.3
# Source repo   : https://github.com/ollama/ollama
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Shalini Salomi Bodapati <Shalini.Salomi.Bodapati@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="ollama"
PACKAGE_VERSION="${1:-v0.33.3}"
PACKAGE_URL="https://github.com/ollama/ollama"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="binutils cmake gcc-toolset-13 gcc-toolset-13-binutils gcc-toolset-13-binutils-devel gcc-toolset-13-gcc-c++ git golang make patch python3 python3-devel python3-pip wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — apply version-specific PowerPC patches for older tags
# =============================================================================
post_clone() {
    local pkg_ver=(${PACKAGE_VERSION#v})
    pkg_ver=(${pkg_ver//./ })

    # Patches validated on v0.12.x up to v0.12.9; v0.12.10+ incorporated these fixes upstream
    if [[ ${pkg_ver[0]} -eq 0 && ${pkg_ver[1]} -eq 12 && ${pkg_ver[2]:-0} -lt 10 ]]; then
        log_info "Applying PowerPC patches for v0.12.x (<0.12.10)"
        wget -q -O build_power.patch https://github.com/ollama/ollama/commit/67b8d3c817fbdc57fedad9b032d0efc10285220a.patch
        wget -q -O set_threads_env.patch https://github.com/ollama/ollama/commit/1364a887a1d7c25522e9c921d55e50a6aea44964.patch
        wget -q -O enable_mma.patch https://github.com/ollama/ollama/commit/fe924304809ae8e6bd6957b0ce5759eb2a796d42.patch
        patch -p1 < build_power.patch
        patch -p1 < set_threads_env.patch
        patch -p1 < enable_mma.patch
    # Patches validated on v0.13.0 and v0.13.1; v0.13.2+ incorporated these fixes upstream
    elif [[ ${pkg_ver[0]} -eq 0 && ${pkg_ver[1]} -eq 13 && ${pkg_ver[2]:-0} -le 1 ]]; then
        log_info "Applying PowerPC patches for v0.13.x (<=0.13.1)"
        wget -q -O ppc_build_fix.patch https://github.com/ollama/ollama/commit/176e9097cf39ea78be4b384940a0e72bd32f3376.patch
        wget -q -O set_threads_env.patch https://github.com/ollama/ollama/commit/a86b8152e0f37c0c117ba7acd2a940e3ba5f07d9.patch
        wget -q -O enable_mma.patch https://github.com/ollama/ollama/commit/7689aded24f76cb02e7bb1c34ad5110a135a9e4b.patch
        patch -p1 < ppc_build_fix.patch
        patch -p1 < set_threads_env.patch
        patch -p1 < enable_mma.patch
    fi
}

# =============================================================================
# CALLBACK: custom_install — compile Ollama via cmake/go and build Python wheel
# =============================================================================
custom_install() {
    log_info "Building Ollama with CMake"
    cmake -B build
    cmake --build build -j"$(nproc)"

    if [[ ! -f "ollama" ]]; then
        log_info "Building Ollama binary with Go"
        local go_tags=""
        if [[ -f "build/lib/ollama/libggml-cpu-power10.so" ]]; then
            export CGO_LDFLAGS="-L$(pwd)/build/lib/ollama/ -lggml-cpu-power10"
            go_tags="--tags ppc64le.power10"
        fi
        go build $go_tags -ldflags "-s -w -X=github.com/ollama/ollama/version.Version=${PACKAGE_VERSION#v}" -o ollama .
    fi

    if [[ ! -f "ollama" ]]; then
        log_error "Ollama build failed: ./ollama binary not found"
        test -f ollama
    fi

    log_info "Creating setup.py and Python package files for wheel generation"
    local pkg_name="ollama_python_package"
    mkdir -p "${pkg_name}/bin" "${pkg_name}/lib"

    cat <<EOF > setup.py
from setuptools import setup, find_packages
from setuptools.command.build_py import build_py
import os, shutil, stat

PYTHON_PACKAGE_NAME = "ollama_python_package"
VERSION = "${PACKAGE_VERSION#v}"

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
            for root, dirs, files in os.walk(LIB_SRC):
                for f in files:
                    if ".so" in f:
                        src = os.path.join(root, f)
                        dst = os.path.join(PKG_LIB_DIR, f)
                        print(f"Copying shared lib: {src}")
                        shutil.copy2(src, dst)
        else:
            print(f"Warning: {LIB_SRC} not found")

        super().run()

setup(
    name=PYTHON_PACKAGE_NAME,
    version=VERSION,
    author="Shalini Salomi Bodapati",
    author_email="Shalini.Salomi.Bodapati@ibm.com",
    description="Ollama binary + shared libs as Python package",
    license="MIT",
    packages=find_packages(include=["ollama_python_package"]),
    include_package_data=False,
    cmdclass={'build_py': CustomBuild},
    package_data={PYTHON_PACKAGE_NAME: ["bin/*", "lib/*"]},
    python_requires=">=3.8",
)
EOF

    cat <<'EOF' > "${pkg_name}/__init__.py"
import subprocess
from pathlib import Path

def run(args=None):
    """Run embedded Ollama binary packaged with this wheel."""
    bin_path = Path(__file__).parent / "bin" / "ollama"
    if not bin_path.exists():
        raise FileNotFoundError("Embedded ollama binary not found.")
    subprocess.run([str(bin_path)] + (args or []))
EOF

    log_info "Installing Python build dependencies for wheel generation"
    python -m pip install --upgrade pip setuptools wheel

    log_info "Building Python wheel (linux_ppc64le) into dist/"
    mkdir -p dist
    python setup.py bdist_wheel --plat-name linux_ppc64le -d dist
}

# =============================================================================
# CALLBACK: custom_test_command — smoke-test Ollama binary and import Python package
# =============================================================================
custom_test_command() {
    log_info "Verifying built Ollama binary"
    ./ollama --version || ./ollama -v || ./ollama --help
    log_info "Verifying installed Python package import"
    python -c "import ollama_python_package; print('ollama_python_package imported successfully')"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
