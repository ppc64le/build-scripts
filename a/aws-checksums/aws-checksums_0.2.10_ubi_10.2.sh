#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : aws-checksums
# Version       : v0.2.10
# Source repo   : https://github.com/awslabs/aws-checksums
# Tested on     : UBI:10.2
# Language      : C
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Prachi Gaonkar <prachi.gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=aws-checksums
PACKAGE_DIR=aws-checksums
SCRIPT_PACKAGE_VERSION=v0.2.10
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/awslabs/aws-checksums
WORKING_DIR=$(pwd)
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

# Dependency: aws-checksums links against aws-c-common and uses its CMake modules
AWS_C_COMMON_VERSION=v0.14.0
AWS_C_COMMON_URL=https://github.com/awslabs/aws-c-common
AWS_C_COMMON_SCRIPT=aws-c-common_${AWS_C_COMMON_VERSION#v}_ubi_10.2.sh
export INDEX_URL_DEVPY="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple"

# Detect CPU generation and set optimization flags accordingly
if grep -q "POWER10" /proc/cpuinfo 2>/dev/null; then
    CPU_FLAGS="-mcpu=power10 -mtune=power10"
    echo "Detected POWER10 — applying power10 optimization flags"
else
    CPU_FLAGS=""
    echo "POWER10 not detected — no arch-specific flags applied"
fi

# Install dependencies 
yum install -y  \
    wget \
    git \
    cmake \
    make \
    gcc \
    python3 \
    python3-pip

# Apply CPU optimization flags
export CFLAGS="${CPU_FLAGS}"

gcc --version
cmake --version

# Clone, build and install aws-c-common into a local prefix (no wheel).
# Used only when neither the DevFirst wheel nor the aws-c-common build script is available.
build_aws_c_common() {
    cd "$WORKING_DIR" || return 1
    rm -rf aws-c-common
    git clone "$AWS_C_COMMON_URL" aws-c-common || return 1
    cd aws-c-common || return 1
    git checkout "$AWS_C_COMMON_VERSION" || return 1
    AWS_C_COMMON_DIR="$(pwd)/local/aws_c_common"
    cmake -S . -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_FLAGS="${CPU_FLAGS}" \
        -DCMAKE_INSTALL_PREFIX="${AWS_C_COMMON_DIR}" \
        -DCMAKE_INSTALL_LIBDIR=lib64 \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_TESTING=OFF || return 1
    cmake --build build -j"$(nproc)" || return 1
    cmake --install build || return 1
    cd "$WORKING_DIR"
}

python3 -m pip install --upgrade pip setuptools wheel

# 1) Install the aws-c-common wheel from the IBM DevFirst wheel index
echo "-------------------Installing aws-c-common from DevFirst portal----------------------"
if python3 -m pip install --only-binary=aws-c-common "aws-c-common==${AWS_C_COMMON_VERSION#v}" --index-url "${INDEX_URL_DEVPY}"; then
    echo "aws-c-common wheel installed from DevFirst"
# 2) Else build it with the existing aws-c-common build script
elif wget -q "https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/a/aws-c-common/${AWS_C_COMMON_SCRIPT}"; then
    echo "aws-c-common wheel not on DevFirst, building with ${AWS_C_COMMON_SCRIPT}"
    if ! bash "${AWS_C_COMMON_SCRIPT}" "$AWS_C_COMMON_VERSION"; then
        echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
        exit 1
    fi
# 3) Else clone and build aws-c-common from source
else
    echo "aws-c-common wheel not on DevFirst and ${AWS_C_COMMON_SCRIPT} not available, building from source"
    if ! build_aws_c_common; then
        echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
        exit 1
    fi
fi
cd "$WORKING_DIR"
# Paths 1 and 2 install the aws_c_common wheel; path 3 already set AWS_C_COMMON_DIR to the source install prefix
AWS_C_COMMON_DIR=${AWS_C_COMMON_DIR:-$(python3 -c "import os, aws_c_common; print(os.path.dirname(aws_c_common.__file__))")}

# Clone source
rm -rf "$PACKAGE_DIR"
if ! git clone "$PACKAGE_URL" "$PACKAGE_DIR"; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Clone_Fails"
    exit 1
fi
cd "$PACKAGE_DIR"
git checkout "$PACKAGE_VERSION"
SOURCE_DIR=$(pwd)

# Local prefix used for wheel packaging. 
mkdir -p local/aws_checksums
PREFIX="${SOURCE_DIR}/local/aws_checksums"

# Build and install aws-checksums
if ! (cmake -S . -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_FLAGS="${CPU_FLAGS}" \
        -DCMAKE_PREFIX_PATH="${AWS_C_COMMON_DIR}" \
        -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
        -DCMAKE_INSTALL_LIBDIR=lib64 \
        -DCMAKE_SKIP_BUILD_RPATH=ON \
        -DCMAKE_INSTALL_RPATH='$ORIGIN:$ORIGIN/../../aws_c_common/lib64' \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_TESTING=ON \
      && cmake --build build -j"$(nproc)" \
      && cmake --install build); then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# Test the build: run the upstream unit tests against the libraries from the build directory
export LD_LIBRARY_PATH="${SOURCE_DIR}/build:${AWS_C_COMMON_DIR}/lib64"
if ! (cd build && ctest --output-on-failure -j"$(nproc)"); then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi

# Create __init__.py so setuptools recognises local/aws_checksums as a Python package
touch local/aws_checksums/__init__.py

# Build Python wheel
python3 -m pip install --upgrade setuptools wheel

# Locate pyproject.toml 
_PYPROJECT_SRC=""
if [ -n "${BUILD_SCRIPT_PATH:-}" ] && [ -f "$(dirname "$BUILD_SCRIPT_PATH")/pyproject.toml" ]; then
    _PYPROJECT_SRC="$(dirname "$BUILD_SCRIPT_PATH")/pyproject.toml"
elif [ -f "${WORKING_DIR}/a/aws-checksums/pyproject.toml" ]; then
    _PYPROJECT_SRC="${WORKING_DIR}/a/aws-checksums/pyproject.toml"
fi

if [ -n "${_PYPROJECT_SRC}" ]; then
    cp "${_PYPROJECT_SRC}" pyproject.toml
else
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/a/aws-checksums/pyproject.toml
fi
sed -i "s/{PACKAGE_VERSION}/${PACKAGE_VERSION#v}/g" pyproject.toml

if ! python3 -m pip wheel . --no-build-isolation --no-deps -w dist \
   || ! python3 -m pip install --force-reinstall --no-deps dist/aws_checksums-*.whl; then
    echo "------------------$PACKAGE_NAME:Wheel_build_fails-------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Wheel_Build_Fails"
    exit 1
fi

# Smoke test: the installed wheel is importable and ships the shared library
if ! python3 -c "import os, aws_checksums; d = os.path.dirname(aws_checksums.__file__); assert os.path.isfile(os.path.join(d, 'lib64', 'libaws-checksums.so')); print('aws_checksums import OK')"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi
# Test the wheel: run the same upstream unit tests again, now against the libraries
# from the installed aws_checksums and aws_c_common wheels
export LD_LIBRARY_PATH=$(python3 -c "import os, aws_checksums; print(os.path.dirname(aws_checksums.__file__))")/lib64:${AWS_C_COMMON_DIR}/lib64
if ! (cd build && ctest --output-on-failure -j"$(nproc)"); then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi

echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"

exit 0
