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
PACKAGE_DIR=faiss/python

# ----------------------------------------------------------------------------
# Install repositories and dependencies
# ----------------------------------------------------------------------------

# Remove stale CentOS Linux 8 / vault.centos.org repo files if present.
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
# Avoid the dependency chain that conflicts with redhat-release on UBI 8.
if ! rpm -q epel-release &>/dev/null; then
    EPEL_RPM=$(mktemp /tmp/epel-release-XXXXXX.rpm)

    curl -fsSL \
        -o "$EPEL_RPM" \
        https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

    rpm -ivh --nodeps --noscripts "$EPEL_RPM"

    rm -f "$EPEL_RPM"
fi

dnf install -y git gcc-toolset-11 cmake file lapack-devel python3.11-devel python3.11-pip python3.11-pytest python3.11-wheel pkg-config swig

# ----------------------------------------------------------------------------
# Build and install OpenBLAS
# ----------------------------------------------------------------------------

cd "$BUILD_HOME"
rm -rf OpenBLAS
git clone --branch v0.3.34 --depth 1 https://github.com/OpenMathLib/OpenBLAS
cd OpenBLAS

make -j"$(nproc)" libs shared
make PREFIX=/usr/local install

# Make /usr/local/lib visible to the runtime linker.
echo "/usr/local/lib" > /etc/ld.so.conf.d/openblas.conf
ldconfig

# Verify OpenBLAS is available.
ldconfig -p | grep openblas

# Enable GCC Toolset 11
source /opt/rh/gcc-toolset-11/enable

# Build and install gflags
cd "$BUILD_HOME"
rm -rf gflags
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

# Install Python dependencies
pip3.11 install --prefer-binary scipy numpy==1.26.4 swig auditwheel patchelf --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux

mkdir -p ~/.local/bin
ln -sf /usr/bin/python3.11 ~/.local/bin/python
ln -sf /usr/bin/python3.11 ~/.local/bin/python3

export PATH="$HOME/.local/bin:$PATH"

# Clone FAISS
cd "$BUILD_HOME"
rm -rf "$PACKAGE_NAME"
git clone "$PACKAGE_URL" -b "$PACKAGE_VERSION"
cd "$PACKAGE_NAME"

# Build FAISS
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

# Build Python wheel
cd faiss/python
rm -rf wheelhouse
mkdir -p wheelhouse/raw

python3.11 -m pip wheel . -w wheelhouse/raw
WHEEL_VERSION="${PACKAGE_VERSION#v}"
RAW_WHEEL=$(find wheelhouse/raw -maxdepth 1 -name "faiss-${WHEEL_VERSION}-*.whl" -print -quit)

if [ -z "$RAW_WHEEL" ]; then
    echo "FAIL: Python wheel was not generated."
    exit 1
fi

# Repair wheel
# Bundle libfaiss.so and other required shared libraries and generate a platform-specific ppc64le wheel.
auditwheel repair "$RAW_WHEEL" -w wheelhouse
rm -f "$RAW_WHEEL"
REPAIRED_WHEEL=$(find wheelhouse -maxdepth 1 -name "faiss-${WHEEL_VERSION}-*.whl" -print -quit)

if [ -z "$REPAIRED_WHEEL" ]; then
    echo "FAIL: Repaired Python wheel was not generated."
    exit 1
fi

# Install repaired wheel
python3.11 -m pip install --force-reinstall "$REPAIRED_WHEEL"
python3.11 -m pip install \
    --force-reinstall \
    --no-deps \
    --only-binary=:all: \
    --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux \
    "numpy==1.26.4"

# Python tests
cd "$BUILD_HOME/$PACKAGE_NAME"
ret=0
python3.11 -m pytest ./tests/test_*.py -v || ret=$?

if [ "$ret" -ne 0 ]; then
    echo "FAIL: ${PACKAGE_NAME} python tests failed."
    exit 2
fi

# Conclude
set +ex
echo "Build and tests complete!"
