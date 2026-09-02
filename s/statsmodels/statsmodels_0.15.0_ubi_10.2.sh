#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : statsmodels
# Version          : v0.15.0
# Source repo      : https://github.com/statsmodels/statsmodels.git
# Tested on        : UBI:10.2
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Shubham Goel <shubham.goel3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
#
# -----------------------------------------------------------------------------

echo "------------------------------------------------------------Cloning statsmodels github repo--------------------------------------------------------------"

PACKAGE_NAME=statsmodels
PACKAGE_VERSION=${1:-v0.15.0}
PACKAGE_URL=https://github.com/statsmodels/statsmodels.git
PACKAGE_DIR=statsmodels
OPENBLAS_VERSION=v0.3.33
OPENBLAS_URL=https://github.com/OpenMathLib/OpenBLAS
OPENBLAS_PREFIX="${INSTALL_ROOT}/openblas"

echo "------------------------------------------------------------Installing requirements------------------------------------------------------"

dnf install -y \
    git wget meson ninja-build \
    libjpeg-devel bzip2-devel libffi-devel zlib-devel \
    libtiff-devel freetype-devel \
    make cmake automake autoconf procps-ng \
    python3.14 python3.14-devel python3.14-pip

yum install gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ gcc-toolset-15-gcc-gfortran -y

# ---------------------------------------------------------------------------
# Activate GCC Toolset 15 (SCL removed in UBI 10 — use PATH export)
# ---------------------------------------------------------------------------
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi

export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:${LD_LIBRARY_PATH:-}"

export CC="/opt/rh/gcc-toolset-15/root/usr/bin/gcc"
export CXX="/opt/rh/gcc-toolset-15/root/usr/bin/g++"

echo "-------------------------------------------------------------Installing Openblas ---------------------------------------------------------"
git clone "${OPENBLAS_URL}"
cd OpenBLAS
git checkout "${OPENBLAS_VERSION}"
git submodule update --init

export USE_OPENMP=1
export USE_THREAD=1
export NUM_THREADS=8
export TARGET=POWER9
export DYNAMIC_ARCH=1
export INTERFACE64=0
export BUILD_BFLOAT16=1
export NO_AFFINITY=1

export CF="${CFLAGS:-} -Wno-unused-parameter -Wno-old-style-declaration"
unset CFLAGS

export LDFLAGS="$(echo "${LDFLAGS:-}" | sed 's/-Wl,--gc-sections//g')"

if [ -n "${FFLAGS:-}" ]; then
    export FFLAGS="${FFLAGS/-fopenmp/ }"
    export FFLAGS="${FFLAGS} -frecursive"
    export LAPACK_FFLAGS="${FFLAGS}"
fi

make -j"${MAX_JOBS}" TARGET="${TARGET}" BUILD_BFLOAT16="${BUILD_BFLOAT16}" BINARY=64 USE_OPENMP="${USE_OPENMP}" USE_THREAD="${USE_THREAD}" NUM_THREADS="${NUM_THREADS}" DYNAMIC_ARCH="${DYNAMIC_ARCH}" INTERFACE64="${INTERFACE64}" NO_AFFINITY="${NO_AFFINITY}" CFLAGS="${CF}" FFLAGS="${FFLAGS:-}"

make install PREFIX="${OPENBLAS_PREFIX}"

export LD_LIBRARY_PATH="${OPENBLAS_PREFIX}/lib:${OPENBLAS_PREFIX}/lib64:${LD_LIBRARY_PATH:-}"
export PKG_CONFIG_PATH="${OPENBLAS_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

pkg-config --modversion openblas

echo "-------------------------------------------------------------Installed Openblas ---------------------------------------------------------"
git clone "$PACKAGE_URL"
cd "$PACKAGE_DIR"
git checkout "$PACKAGE_VERSION"

echo "------------------------------------------------------------Installing Python dependencies------------------------------------------------------"

python3.14 -m pip install --upgrade pip setuptools wheel

python3.14 -m pip install \
    "pytest==9.1.1" \
    "pytest-randomly==4.1.0" \
    "pytest-run-parallel==0.10.0" \
    "cython==3.3.0" \
    "setuptools-scm>=9.2.0,<10" \
    meson \
    meson-python \
    ninja

if python3.14 --version | grep -Eq "3\.(11|12|13|14)"; then
    python3.14 -m pip install \
        "numpy==2.5.0" \
        "scipy==1.18.0" \
        "pandas==3.0.5" \
        "patsy==1.0.2"
fi

echo "------------------------------------------------------------Installing statsmodels------------------------------------------------------"

if ! python3.14 -m pip install --no-build-isolation .; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

echo "------------------------------------------------------------Running tests------------------------------------------------------"
cd $PACKAGE_DIR
export PYTEST_ADDOPTS="--continue-on-collection-errors"

if ! python3.14 -m pytest --import-mode=importlib \
    --ignore=tsa/tests/test_stattools.py \
    --ignore=tsa/statespace/tests; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_Test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi