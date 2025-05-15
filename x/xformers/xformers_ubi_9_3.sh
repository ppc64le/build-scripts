#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : xformers
# Version       : v0.0.29
# Source repo   : https://github.com/facebookresearch/xformers.git
# Tested on     : UBI 9.3
# Language      : Python, C++
# Travis-Check  : True
# Script License: Apache License, Version 2.0
# Maintainer    : Puneet Sharma <Puneet.Sharma21@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=xformers
PACKAGE_VERSION=${1:-v0.0.29}
PACKAGE_URL=https://github.com/facebookresearch/xformers.git
PACKAGE_DIR=xformers
BUILD_DEPS=${BUILD_DEPS:-true}
PARALLEL=${PARALLEL:-$(nproc)}
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
export _GLIBCXX_USE_CXX11_ABI=1

# Install dependencies
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
    git gcc-toolset-13 ninja-build rust cargo \
    python-devel python-pip jq pkg-config atlas

source /opt/rh/gcc-toolset-13/enable

curl -sL https://ftp2.osuosl.org/pub/ppc64el/openblas/latest/Openblas_0.3.29_ppc64le.tar.gz | tar xvf - -C /usr/local \
&& export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig/

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib64:/usr/local/lib:/usr/lib64:/usr/lib

# Clone repository
if [ -z $PACKAGE_SOURCE_DIR ]; then
  git clone $PACKAGE_URL
  cd $PACKAGE_NAME
else
  cd $PACKAGE_SOURCE_DIR
fi

git checkout $PACKAGE_VERSION
git submodule update --init

# Install Python dependencies
pip3 install --upgrade pip setuptools wheel
pip3 install ninja 'cmake<4' 'pytest==8.2.2' hydra-core


# Check BUILD_DEPS passed from Jenkins
echo "BUILD_DEPS: $BUILD_DEPS"

# Install PyTorch only if not installed and BUILD_DEPS is not False
if [ -z $BUILD_DEPS ] || [ "$BUILD_DEPS" == "true" ]; then

    # Install dependency - pytorch
    PYTORCH_VERSION=v2.5.1

    git clone https://github.com/pytorch/pytorch.git

    cd pytorch

    git checkout tags/$PYTORCH_VERSION

    PPC64LE_PATCH="69cbf05"

    if ! git log --pretty=format:"%H" | grep -q "$PPC64LE_PATCH"; then
        echo "Applying POWER patch."
        git config user.email "Puneet.Sharma21@ibm.com"
        git config user.name "puneetsharma21"
        git cherry-pick "$PPC64LE_PATCH"
    else
        echo "POWER patch not needed."
    fi

    git submodule sync
    git submodule update --init --recursive

    # Set flags to suppress warnings
    export CXXFLAGS="-Wno-unused-variable -Wno-unused-parameter"

    pip3 install -r requirements.txt
    MAX_JOBS=$PARALLEL python3 setup.py install


    cd ..
else
    echo "Skipping PyTorch installation because BUILD_DEPS is set to False or not provided."
    python3 -m pip install -r requirements.txt
fi

# Build and install xformers
if ! pip3 install . -vvv; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail |  Build_fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:Build_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_Success"
fi

# Test installation
if python3 -c "import xformers"; then
    echo "------------------$PACKAGE_NAME::Install_Success---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_Success"
else
    echo "------------------$PACKAGE_NAME::Install_Fail-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail |  Install_Fails"
    exit 2
fi

# Run Specific tests
export PY_IGNORE_IMPORTMISMATCH=1

# Define the test directory and test files
TEST_DIR="tests"
TEST_FILES=("test_unbind.py" "test_rotary_embeddings.py" "test_hydra_helper.py" "test_compositional_attention.py" "test_global_attention.py")

# Initialize an empty array to hold available test files
AVAILABLE_TESTS=()

# Check for existence of each test file
for TEST_FILE in "${TEST_FILES[@]}"; do
    if [ -f "$TEST_DIR/$TEST_FILE" ]; then
        AVAILABLE_TESTS+=("$TEST_DIR/$TEST_FILE")
        echo "Available Tests: $AVAILABLE_TESTS"
    else
        echo "Warning: $TEST_DIR/$TEST_FILE is missing. Skipping."
    fi
done

# Run pytest with available test files
if ! pytest "${AVAILABLE_TESTS[@]}"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:both_install_and_test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi