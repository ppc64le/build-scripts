#!/bin/bash -ex
# ----------------------------------------------------------------------------
# Package        : faiss
# Version        : v1.9.0
# Source repo    : https://github.com/facebookresearch/faiss.git
# Tested on      : UBI 9.8
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
PACKAGE_DIR=faiss/python

# ----------------------------------------------------------------------------
# Install repositories and dependencies
# ----------------------------------------------------------------------------

# Remove stale CentOS Linux 8 / vault.centos.org repo files if present.
find /etc/yum.repos.d/ -maxdepth 1 -name "*.repo" \
    ! -name "ubi.repo" \
    ! -name "redhat.repo" \
    ! -name "almalinux9.repo" \
    -delete 2>/dev/null || true

# AlmaLinux 9 is ABI-compatible with RHEL 9 and fully supports ppc64le.
cat > /etc/yum.repos.d/almalinux9.repo << 'EOF'
[al9-baseos]
name=AlmaLinux 9 - BaseOS
baseurl=https://repo.almalinux.org/almalinux/9/BaseOS/ppc64le/os/
gpgcheck=0
enabled=1

[al9-appstream]
name=AlmaLinux 9 - AppStream
baseurl=https://repo.almalinux.org/almalinux/9/AppStream/ppc64le/os/
gpgcheck=0
enabled=1

[al9-crb]
name=AlmaLinux 9 - CRB
baseurl=https://repo.almalinux.org/almalinux/9/CRB/ppc64le/os/
gpgcheck=0
enabled=1
EOF

dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf install -y git gcc gcc-c++ cmake file lapack-devel-3.9.0-8.el9.ppc64le swig python3.11-devel python3.11-pip python3.11-pytest python3.11-wheel

pip3.11 install --prefer-binary scipy numpy==1.26.4 auditwheel patchelf --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux

mkdir -p ~/.local/bin
ln -sf /usr/bin/python3.11 ~/.local/bin/python
ln -sf /usr/bin/python3.11 ~/.local/bin/python3
export PATH="$HOME/.local/bin:$PATH"

# ----------------------------------------------------------------------------
# Build and install OpenBLAS
# ----------------------------------------------------------------------------

cd "$BUILD_HOME"
git clone https://github.com/OpenMathLib/OpenBLAS
cd OpenBLAS
git checkout v0.3.29

make -j"$(nproc)" TARGET=POWER8 DYNAMIC_ARCH=1 DYNAMIC_OLDER=1 USE_OPENMP=0 NUM_THREADS=20 NO_AFFINITY=1
make install

# ----------------------------------------------------------------------------
# Build and install gflags
# ----------------------------------------------------------------------------

cd "$BUILD_HOME"
git clone --branch v2.3.0 --depth 1 https://github.com/gflags/gflags.git
cd gflags
mkdir build
cd build

cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/opt/gflags-2.3.0 \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_STATIC_LIBS=OFF \
    -DBUILD_TESTING=OFF

make -j"$(nproc)"
make install

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
    ..

ret=0
make -j"$(nproc)" || ret=$?

if [ "$ret" -ne 0 ]; then
    echo "FAIL: ${PACKAGE_NAME} Build failed."
    exit 1
fi

# Verify native libraries
file faiss/libfaiss.so
file faiss/python/_swigfaiss.so

# Run FAISS C++ tests
ret=0
make test || ret=$?

if [ "$ret" -ne 0 ]; then
    echo "FAIL: ${PACKAGE_NAME} C++ tests failed."
    exit 2
fi

# ----------------------------------------------------------------------------
# Build Python wheel
# ----------------------------------------------------------------------------

cd "$PACKAGE_DIR"
rm -rf dist wheelhouse
mkdir -p dist wheelhouse

python3.11 -m pip wheel . -w dist

WHEEL_VERSION="${PACKAGE_VERSION#v}"
RAW_WHEEL=$(find dist -maxdepth 1 -name "faiss-${WHEEL_VERSION}-*.whl" -print -quit)

if [ -z "$RAW_WHEEL" ]; then
    echo "FAIL: Python wheel was not generated."
    exit 1
fi

# Repair wheel
# Bundle required shared libraries and generate a ppc64le wheel.
auditwheel repair "$RAW_WHEEL" -w wheelhouse

REPAIRED_WHEEL=$(find wheelhouse -maxdepth 1 -name "faiss-${WHEEL_VERSION}-*.whl" -print -quit)

if [ -z "$REPAIRED_WHEEL" ]; then
    echo "FAIL: Repaired Python wheel was not generated."
    exit 1
fi

# Install repaired wheel
python3.11 -m pip install --force-reinstall "$REPAIRED_WHEEL"

# ----------------------------------------------------------------------------
# Python tests
# ----------------------------------------------------------------------------

cd "$BUILD_HOME/$PACKAGE_NAME"

ret=0
python3.11 -m pytest ./tests/test_*.py -v || ret=$?

if [ "$ret" -ne 0 ]; then
    echo "FAIL: ${PACKAGE_NAME} Python tests failed."
    exit 2
fi

# Conclude
set +ex
echo "Build and tests complete!"
