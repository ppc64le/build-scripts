#!/bin/bash 
# -----------------------------------------------------------------------------
#
# Package         : OpenBLAS
# Version         : v0.3.23
# Source repo     : https://github.com/xianyi/OpenBLAS
# Tested on       : UBI: 9.3
# Language        : C
# Travis-Check    : True
# Script License  : Apache License, Version 2 or later
# Maintainer      : Stuti Wali <Stuti.Wali@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -ex

# Variables
PACKAGE_NAME=OpenBLAS
PACKAGE_VERSION=${1:-v0.3.23}
PACKAGE_URL=https://github.com/xianyi/OpenBLAS
OPENBLAS_VERSION=${PACKAGE_VERSION}
PREFIX=local/openblas

# Install dependencies
yum install -y git gcc gcc-c++ make cmake wget openssl-devel bzip2-devel libffi-devel zlib-devel python-devel python-pip libjpeg-devel zlib-devel freetype-devel procps-ng 

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


# Set build options
declare -a build_opts

# Fix ctest not automatically discovering tests
LDFLAGS=$(echo "${LDFLAGS}" | sed "s/-Wl,--gc-sections//g")

# See this workaround: https://github.com/xianyi/OpenBLAS/issues/818#issuecomment-207365134
export CF="${CFLAGS} -Wno-unused-parameter -Wno-old-style-declaration"
unset CFLAGS

export USE_OPENMP=1
build_opts+=(USE_OPENMP=${USE_OPENMP})
export PREFIX=${PREFIX}

# Handle Fortran flags
if [ ! -z "$FFLAGS" ]; then
    export FFLAGS="${FFLAGS/-fopenmp/ }"
    export FFLAGS="${FFLAGS} -frecursive"
    export LAPACK_FFLAGS="${FFLAGS}"
fi

export PLATFORM=$(uname -m)
build_opts+=(BINARY="64")
build_opts+=(DYNAMIC_ARCH=1)
build_opts+=(TARGET="POWER9")
BUILD_BFLOAT16=1

# Placeholder for future builds that may include ILP64 variants.
build_opts+=(INTERFACE64=0)
build_opts+=(SYMBOLSUFFIX="")

# Build LAPACK
build_opts+=(NO_LAPACK=0)

# Enable threading and set the number of threads
build_opts+=(USE_THREAD=1)
build_opts+=(NUM_THREADS=8)

# Disable CPU/memory affinity handling to avoid problems with NumPy and R
build_opts+=(NO_AFFINITY=1)

# Build OpenBLAS
if ! (make -j8 ${build_opts[@]} HOST=${HOST} CROSS_SUFFIX="${HOST}-" CFLAGS="${CF}" FFLAGS="${FFLAGS}") ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Install OpenBLAS
CFLAGS="${CF}" FFLAGS="${FFLAGS}" make install PREFIX="${PREFIX}" ${build_opts[@]}
echo "Current path is -----------------------------------------------------------------"
echo $PWD

# Create pyproject.toml dynamically
cat <<EOF > pyproject.toml
[build-system]
# Minimum requirements for the build system to execute.
requires = [
    "setuptools",
    "wheel",
]
build-backend = "setuptools.build_meta"

[project]
name = "openblas"
version = "v0.3.23"
requires-python = ">=3.10"
description = "Provides OpenBLAS for python packaging"
readme = "README.md"
classifiers = [
  "Development Status :: 5 - Production/Stable",
  "Programming Language :: C++",
  "License :: OSI Approved :: BSD License",
]
license = {file = "LICENSE.txt"}

[project.urls]
homepage = "https://github.com/xianyi/OpenBLAS"
upstream = "https://github.com/xianyi/OpenBLAS"

[tool.setuptools.packages.find]
# scanning for namespace packages is true by default in pyproject.toml, so
# # you do NOT need to include the following line.
namespaces = true
where = ["local"]

[options]
install_requires = "importlib-metadata ~= 1.0 ; python_version < '3.8'"

[tool.setuptools.package-data]
openblas = ["lib/*", "include/*", "lib/pkgconfig/*", "lib/cmake/openblas/*"]
EOF

# Run test cases
if !(make -C utest all); then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
