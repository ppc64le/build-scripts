#!/bin/bash -ex
# ----------------------------------------------------------------------------
# Package        : faiss
# Version        : v1.9.0
# Source repo    : https://github.com/facebookresearch/faiss.git
# Tested on      : UBI 8.10
# Language       : C++
# Ci-Check       : true
# Maintainer     : Amit Kumar <amit.kumar282@ibm.com>
# Script License : Apache License, Version 2.0 or later
#
# Disclaimer     : This script has been tested in root mode on the specified
#                  platform and package version. Functionality with newer
#                  versions of the package or OS is not guaranteed.
# ----------------------------------------------------------------------------

# Configuration
PACKAGE_NAME="faiss"
PACKAGE_ORG="facebookresearch"
PACKAGE_VERSION="v1.9.0"
PACKAGE_URL="https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}.git"
BUILD_HOME=$(pwd)

# ----------------------------------------------------------------------------
# Install repositories and dependencies
# ----------------------------------------------------------------------------

# Remove any stale CentOS Linux 8 / vault.centos.org repo files that may be
# baked into the base image and cause timeout failures at metadata fetch time.
find /etc/yum.repos.d/ -maxdepth 1 -name "*.repo" \
    ! -name "ubi.repo" \
    ! -name "redhat.repo" \
    ! -name "almalinux8.repo" \
    -delete 2>/dev/null || true

# Enable UBI repos already present in the UBI 8 container.
dnf install -y dnf-plugins-core

dnf config-manager \
    --set-enabled \
    ubi-8-baseos-rpms \
    ubi-8-appstream-rpms \
    ubi-8-codeready-builder-rpms 2>/dev/null || true

# Add AlmaLinux 8 repositories for packages not available in UBI.
# AlmaLinux 8 is ABI-compatible with RHEL 8 and supports ppc64le.
cat > /etc/yum.repos.d/almalinux8.repo << 'EOF'
[al8-baseos]
name=AlmaLinux 8 - BaseOS
baseurl=https://repo.almalinux.org/almalinux/8/BaseOS/ppc64le/os/
gpgcheck=0
enabled=1
excludepkgs=almalinux-release* almalinux-repos* almalinux-gpg-keys*

[al8-appstream]
name=AlmaLinux 8 - AppStream
baseurl=https://repo.almalinux.org/almalinux/8/AppStream/ppc64le/os/
gpgcheck=0
enabled=1
excludepkgs=almalinux-release* almalinux-repos* almalinux-gpg-keys*

[al8-powertools]
name=AlmaLinux 8 - PowerTools
baseurl=https://repo.almalinux.org/almalinux/8/PowerTools/ppc64le/os/
gpgcheck=0
enabled=1
excludepkgs=almalinux-release* almalinux-repos* almalinux-gpg-keys*
EOF

# EPEL for any remaining dependencies.
# Use rpm --nodeps --noscripts to avoid the epel-release -> almalinux-release
# dependency chain that conflicts with redhat-release on UBI 8.
if ! rpm -q epel-release &>/dev/null; then
    EPEL_RPM=$(mktemp /tmp/epel-release-XXXXXX.rpm)

    curl -fsSL \
        -o "$EPEL_RPM" \
        https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

    rpm -ivh --nodeps --noscripts "$EPEL_RPM"

    rm -f "$EPEL_RPM"
fi

dnf install -y git gcc-toolset-12 cmake file lapack-devel python3-devel python3-pip pkg-config swig unzip

# ----------------------------------------------------------------------------
# Enable GCC Toolset
# ----------------------------------------------------------------------------

source /opt/rh/gcc-toolset-12/enable

# ----------------------------------------------------------------------------
# Build and install OpenBLAS
# ----------------------------------------------------------------------------

cd "$BUILD_HOME"

rm -rf OpenBLAS

git clone https://github.com/OpenMathLib/OpenBLAS
cd OpenBLAS
git checkout v0.3.34

# Build libraries and shared objects without running the OpenBLAS test suite.
ret=0
make -j"$(nproc)" libs || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "FAIL: OpenBLAS build failed."
    exit 1
fi
make -j"$(nproc)" shared
make PREFIX=/usr/local install

# Make /usr/local/lib visible to the runtime linker.
echo "/usr/local/lib" > /etc/ld.so.conf.d/openblas.conf
ldconfig

# Verify OpenBLAS is available.
ldconfig -p | grep openblas

# ----------------------------------------------------------------------------
# Build and install gflags
# ----------------------------------------------------------------------------

cd "$BUILD_HOME"

rm -rf gflags

git clone \
    --branch v2.3.0 \
    --depth 1 \
    https://github.com/gflags/gflags.git

cd gflags
mkdir build
cd build

cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/opt/gflags-2.3.0 \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_STATIC_LIBS=OFF \
    -DBUILD_TESTING=OFF

ret=0
make -j"$(nproc)" || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "FAIL: gflags build failed."
    exit 1
fi
make install

# ----------------------------------------------------------------------------
# Detect Python and create virtual environment
# ----------------------------------------------------------------------------

PYTHON_BIN=$(command -v python3 || command -v python)
"${PYTHON_BIN}" -m venv "$BUILD_HOME/faiss-env"
source "$BUILD_HOME/faiss-env/bin/activate"

# Download numpy ppc64le wheel directly from IBM index and install from disk.
# UBI 8 has glibc 2.28 — use manylinux_2_27 wheels.
PYVER=$("${PYTHON_BIN}" -c "import sys; print(f'cp{sys.version_info.major}{sys.version_info.minor}')")
NUMPY_WHL="numpy-2.4.6+ppc64le1-${PYVER}-${PYVER}-manylinux_2_27_ppc64le.whl"
curl -fsSL \
    "https://wheels.developerfirst.ibm.com/ppc64le/linux/${NUMPY_WHL}" \
    -o "/tmp/${NUMPY_WHL}"
pip install "/tmp/${NUMPY_WHL}"
rm -f "/tmp/${NUMPY_WHL}"

# ----------------------------------------------------------------------------
# Install Python dependencies
# ----------------------------------------------------------------------------

pip install \
    --prefer-binary \
    pytest \
    wheel \
    scipy \
    swig \
    auditwheel \
    patchelf

# ----------------------------------------------------------------------------
# Clone FAISS
# ----------------------------------------------------------------------------

cd "$BUILD_HOME"

rm -rf "$PACKAGE_NAME"

git clone "$PACKAGE_URL" -b "$PACKAGE_VERSION"

cd "$PACKAGE_NAME"

# ----------------------------------------------------------------------------
# Build FAISS
# ----------------------------------------------------------------------------

mkdir build
cd build

cmake \
    -DFAISS_ENABLE_GPU=OFF \
    -DFAISS_ENABLE_PYTHON=ON \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_TESTING=ON \
    -DFAISS_ENABLE_C_API=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DPython_EXECUTABLE="$(command -v python)" \
    ..

ret=0
make -j"$(nproc)" || ret=$?

if [ "$ret" -ne 0 ]; then
    echo "FAIL: Build failed."
    exit 1
fi

# ----------------------------------------------------------------------------
# Verify native libraries
# ----------------------------------------------------------------------------

file faiss/libfaiss.so
file faiss/python/_swigfaiss.so

# ----------------------------------------------------------------------------
# Run FAISS C++ tests
# ----------------------------------------------------------------------------

ret=0
make test || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "FAIL: C++ tests failed."
    exit 2
fi

# ----------------------------------------------------------------------------
# Build Python wheel
# ----------------------------------------------------------------------------

cd faiss/python

rm -rf wheelhouse
mkdir -p wheelhouse/raw

ret=0
python -m pip wheel . -w wheelhouse/raw || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "FAIL: Python wheel build failed."
    exit 1
fi

RAW_WHEEL=$(find wheelhouse/raw -maxdepth 1 \
    -name "faiss-1.9.0-*.whl" -print -quit)

if [ -z "$RAW_WHEEL" ]; then
    echo "FAIL: Python wheel was not generated."
    exit 1
fi

echo "Raw wheel:"
echo "$RAW_WHEEL"

# ----------------------------------------------------------------------------
# Repair wheel
#
# Bundle libfaiss.so and other required shared libraries and generate a
# platform-specific ppc64le wheel.
# ----------------------------------------------------------------------------

auditwheel repair \
    "$RAW_WHEEL" \
    -w wheelhouse

# Remove the unrepaired wheel so wheelhouse contains only the publishable
# repaired wheel.
rm -f "$RAW_WHEEL"

REPAIRED_WHEEL=$(find wheelhouse -maxdepth 1 \
    -name "faiss-1.9.0-*.whl" -print -quit)

if [ -z "$REPAIRED_WHEEL" ]; then
    echo "FAIL: Repaired wheel was not generated."
    exit 1
fi

echo "Repaired wheel:"
echo "$REPAIRED_WHEEL"

# ----------------------------------------------------------------------------
# Verify repaired wheel contents
# ----------------------------------------------------------------------------

echo "=== Repaired wheel contents ==="

unzip -l "$REPAIRED_WHEEL" \
    | grep -E 'libfaiss|_swigfaiss|\.libs'

if ! unzip -l "$REPAIRED_WHEEL" | grep -q 'libfaiss'; then
    echo "FAIL: Repaired wheel does not contain libfaiss."
    exit 1
fi

echo "=== Auditwheel information ==="

auditwheel show "$REPAIRED_WHEEL"

# ----------------------------------------------------------------------------
# Install repaired wheel
# ----------------------------------------------------------------------------

pip install \
    --force-reinstall \
    "$REPAIRED_WHEEL"

# ----------------------------------------------------------------------------
# Verify Python imports
# ----------------------------------------------------------------------------

python -c "import numpy; print('NumPy:', numpy.__version__)"

python -c "import faiss; print('FAISS:', faiss.__version__)"

# ----------------------------------------------------------------------------
# Python tests
# ----------------------------------------------------------------------------

cd "$BUILD_HOME/$PACKAGE_NAME"

ret=0
python -m pytest ./tests/test_*.py -v || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "FAIL: Python tests failed."
    exit 2
fi

# ----------------------------------------------------------------------------
# Conclude
# ----------------------------------------------------------------------------

set +ex

echo "Build and tests complete!"
echo "Publishable wheel:"
echo "$BUILD_HOME/$PACKAGE_NAME/build/faiss/python/$REPAIRED_WHEEL"
echo "Libraries available at [$BUILD_HOME/$PACKAGE_NAME/build/faiss/]"
