#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : scikit-image
# Version       : v0.26.0
# Source repo   : https://github.com/scikit-image/scikit-image
# Tested on     : UBI 10.2
# Language      : Python, Cython, C, C++
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shubham Goel <shubham.goel3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=scikit-image
PACKAGE_VERSION=${1:-v0.26.0}
PACKAGE_URL=https://github.com/scikit-image/scikit-image

OS_NAME=`cat /etc/os-release | grep "PRETTY" | awk -F '=' '{print $2}'`

# install core dependencies
yum install -y python3.14 python3.14-devel python3.14-pip gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ gcc-toolset-15-gcc-gfortran git pkg-config zlib-devel libjpeg-turbo-devel

SCRIPT_DIR=$(pwd)

# Enable GCC Toolset 15
export PATH=/opt/rh/gcc-toolset-15/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-15/root/usr/lib64:${LD_LIBRARY_PATH:-}

export CC="$(which gcc)"
export CXX="$(which g++)"
export FC="$(which gfortran)"

echo "Compiler configuration:"
echo "CC=${CC}"
echo "CXX=${CXX}"
echo "FC=${FC}"

gcc --version
g++ --version
gfortran --version

echo "---------------------------------------openblas installing----------------------------------"
OPENBLAS_VERSION=v0.3.33
OPENBLAS_URL=https://github.com/OpenMathLib/OpenBLAS
OPENBLAS_PREFIX="${INSTALL_ROOT}/openblas"

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

cd $SCRIPT_DIR

echo "---------------------------------------openblas installed-----------------------------------------"

echo "-------------------------------------clone scikit-image repo----------------------------------------"

# clone source repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

# Create a virtualenv named ``skimage-dev`` that lives outside of the repository.
mkdir -p ~/envs
python3.14 -m venv ~/envs/skimage-dev
source ~/envs/skimage-dev/bin/activate

python --version
python3.14 -m pip install --upgrade pip setuptools wheel

# -----------------------------------------------------------------------------
# Install runtime dependencies (requirements/default.txt)
# numpy>=2.1, scipy>=1.15, networkx>=3.0, pillow>=10.1,
# imageio>=2.33,!=2.35.0, tifffile>=2025.1.10, packaging>=24, lazy-loader>=0.5
# -----------------------------------------------------------------------------

python3.14 -m pip install \
    "numpy==2.5.0" \
    "scipy==1.18.0" \
    "networkx>=3.0" \
    "pillow>=10.1" \
    "imageio>=2.33,!=2.35.0" \
    "tifffile>=2025.1.10" \
    "packaging>=24" \
    "lazy-loader>=0.5"

# -----------------------------------------------------------------------------
# Install build dependencies (requirements/build.txt)
# meson-python>=0.16, ninja>=1.11.1.1, Cython>=3.0.10,!=3.2.0b1,
# pythran>=0.16, spin>=0.13, build>=1.2.1
# -----------------------------------------------------------------------------

python3.14 -m pip install \
    "meson-python>=0.16" \
    "ninja>=1.11.1.1" \
    "Cython>=3.0.10,!=3.2.0b1" \
    "pythran>=0.16" \
    "spin>=0.13" \
    "build>=1.2.1"

# -----------------------------------------------------------------------------
# Install test dependencies (requirements/test.txt)
# numpydoc>=1.7, pooch>=1.6.0, pytest>=9, pytest-cov>=2.11.0,
# pytest-pretty, pytest-localserver, pytest-doctestplus>=1.6.0
# -----------------------------------------------------------------------------

python3.14 -m pip install \
    "numpydoc>=1.7" \
    "pooch>=1.6.0" \
    "pytest>=9" \
    "pytest-cov>=2.11.0" \
    pytest-pretty \
    pytest-localserver \
    "pytest-doctestplus>=1.6.0"

# build and install
if ! python3.14 -m pip install -e . --no-build-isolation; then
        echo "------------------$PACKAGE_NAME:build_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:build_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_Success"

        python3.14 -m pip show scikit-image
        python3.14 -c "import skimage; print(skimage.__version__)"
        if [ $? == 0 ]; then
                echo "------------------$PACKAGE_NAME:install_success-------------------------"
                echo "$PACKAGE_VERSION $PACKAGE_NAME"
                echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_Success"
        else
                echo "------------------$PACKAGE_NAME:install_fails---------------------"
                echo "$PACKAGE_URL $PACKAGE_NAME"
                echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
                exit 1
        fi
fi

# test some functionality
if ! python3.14 -m pytest tests/skimage/filters/test_unsharp_mask.py; then
     echo "------------------$PACKAGE_NAME::Test_Fail-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Test_Fail"
     exit 2
else
     echo "------------------$PACKAGE_NAME::Test_Pass---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Test_Success"
     deactivate
     exit 0
fi
