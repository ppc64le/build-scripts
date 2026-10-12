#!/bin/bash -ex
# ----------------------------------------------------------------------------
# Package        : faiss
# Version        : v1.9.0
# Source repo    : https://github.com/facebookresearch/faiss.git
# Tested on      : UBI 10.2
# Language       : C++
# Ci-Check       : true
# Maintainer     : Amit Kumar <amit.kumar282@ibm.com>
# Script License : Apache License, Version 2.0 or later
#
# Disclaimer     : This script has been tested in root mode on the specified
#                  platform and package version. Functionality with newer
#                  versions of the package or OS is not guaranteed.
# ----------------------------------------------------------------------------

PACKAGE_NAME="faiss"
PACKAGE_ORG="facebookresearch"
PACKAGE_VERSION="v1.9.0"
PACKAGE_URL="https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}.git"
PACKAGE_DIR="faiss"
BUILD_HOME="${HOME:-/root}"
cd "$BUILD_HOME"
POWER10_FLAGS="-mcpu=power10 -mtune=power10 -O3"
# ----------------------------------------------------------------------------
# Install repositories and dependencies
# ----------------------------------------------------------------------------

find /etc/yum.repos.d/ -maxdepth 1 -name "*.repo" \
    ! -name "ubi.repo" \
    ! -name "redhat.repo" \
    ! -name "almalinux10.repo" \
    -delete 2>/dev/null || true

cat > /etc/yum.repos.d/almalinux10.repo << 'EOF'
[al10-baseos]
name=AlmaLinux 10 - BaseOS
baseurl=https://repo.almalinux.org/almalinux/10/BaseOS/ppc64le/os/
gpgcheck=0
enabled=1

[al10-appstream]
name=AlmaLinux 10 - AppStream
baseurl=https://repo.almalinux.org/almalinux/10/AppStream/ppc64le/os/
gpgcheck=0
enabled=1

[al10-crb]
name=AlmaLinux 10 - CRB
baseurl=https://repo.almalinux.org/almalinux/10/CRB/ppc64le/os/
gpgcheck=0
enabled=1
EOF

dnf install -y --allowerasing \
    git gcc gcc-c++ gcc-gfortran cmake file python3.12 python3.12-devel pkg-config swig unzip

gcc --version
g++ --version

# ----------------------------------------------------------------------------
# Build and install OpenBLAS
# ----------------------------------------------------------------------------

cd "$BUILD_HOME"
rm -rf OpenBLAS
git clone https://github.com/OpenMathLib/OpenBLAS
cd OpenBLAS
git checkout v0.3.34
git submodule update --init

ret=0
make -j"$(nproc)" \
    TARGET=POWER10 \
    DYNAMIC_ARCH=1 \
    USE_OPENMP=1 \
    USE_THREAD=1 \
    NUM_THREADS=8 \
    NO_AFFINITY=1 \
    CFLAGS="${POWER10_FLAGS}" \
    FFLAGS="${POWER10_FLAGS}" \
    libs shared || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "FAIL: OpenBLAS build failed."
    exit 1
fi
make PREFIX=/usr/local install

echo "/usr/local/lib" > /etc/ld.so.conf.d/openblas.conf
ldconfig
ldconfig -p | grep openblas

# ----------------------------------------------------------------------------
# Build and install gflags
# ----------------------------------------------------------------------------

cd "$BUILD_HOME"
rm -rf gflags
git clone --branch v2.3.0 --depth 1 https://github.com/gflags/gflags.git
cd gflags
mkdir build
cd build

cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/opt/gflags-2.3.0 \
    -DCMAKE_C_FLAGS="${POWER10_FLAGS}" \
    -DCMAKE_CXX_FLAGS="${POWER10_FLAGS}" \
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

PYTHON_BIN=$(command -v python3.12 || true)
if [ -z "$PYTHON_BIN" ]; then
    echo "ERROR: python3.12 not found. Ensure python3.12 is installed."
    exit 1
fi
"${PYTHON_BIN}" -m venv "$BUILD_HOME/faiss-env"
source "$BUILD_HOME/faiss-env/bin/activate"

# ----------------------------------------------------------------------------
# Install Python dependencies
# ----------------------------------------------------------------------------

pip install numpy==2.5.2 \
    --extra-index-url https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/

pip install --prefer-binary pytest wheel scipy swig auditwheel patchelf

# ----------------------------------------------------------------------------
# Clone FAISS
# ----------------------------------------------------------------------------

cd "$BUILD_HOME"
rm -rf "$PACKAGE_DIR"
git clone "$PACKAGE_URL" -b "$PACKAGE_VERSION" "$PACKAGE_DIR"

# ----------------------------------------------------------------------------
# Build FAISS C++ core
# ----------------------------------------------------------------------------

cd "$BUILD_HOME/$PACKAGE_DIR"
rm -rf build
mkdir build
cd build

cmake \
    -DFAISS_ENABLE_GPU=OFF \
    -DFAISS_ENABLE_PYTHON=ON \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_TESTING=ON \
    -DFAISS_ENABLE_C_API=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS="${POWER10_FLAGS}" \
    -DCMAKE_CXX_FLAGS="${POWER10_FLAGS}" \
    -DBLA_VENDOR=OpenBLAS \
    -DCMAKE_PREFIX_PATH=/opt/gflags-2.3.0 \
    -DPython_EXECUTABLE="$(command -v python)" \
    ..

ret=0
make -j"$(nproc)" || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "FAIL: FAISS C++ build failed."
    exit 1
fi

file faiss/libfaiss.so
file faiss/python/_swigfaiss.so

# ----------------------------------------------------------------------------
# Build Python wheel
# ----------------------------------------------------------------------------

cd "$BUILD_HOME/$PACKAGE_DIR/build/faiss/python"

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
# ----------------------------------------------------------------------------

auditwheel repair "$RAW_WHEEL" -w wheelhouse

rm -f "$RAW_WHEEL"

REPAIRED_WHEEL=$(find wheelhouse -maxdepth 1 \
    -name "faiss-1.9.0-*.whl" -print -quit)

if [ -z "$REPAIRED_WHEEL" ]; then
    echo "FAIL: Repaired wheel was not generated."
    exit 1
fi

echo "Repaired wheel: ${REPAIRED_WHEEL}"

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

pip install --force-reinstall "$REPAIRED_WHEEL"

# ----------------------------------------------------------------------------
# Verify Python imports
# ----------------------------------------------------------------------------

python -c "import numpy; print('NumPy:', numpy.__version__)"
python -c "import faiss; print('FAISS:', faiss.__version__)"

# ----------------------------------------------------------------------------
# Python tests
# ----------------------------------------------------------------------------

cd "$BUILD_HOME/$PACKAGE_DIR"

# TestPreassigned::test_float is excluded — known upstream bug in v1.9.0:
ret=0
python -m pytest ./tests/test_*.py -v -p no:faulthandler -k "not (TestPreassigned and test_float)" || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "FAIL: Python tests failed."
    exit 2
fi

# ----------------------------------------------------------------------------
# Conclude
# ----------------------------------------------------------------------------
echo "Build and tests complete!"
echo "Publishable wheel: $REPAIRED_WHEEL"
echo "Libraries available at [$BUILD_HOME/$PACKAGE_DIR/build/faiss/]"
