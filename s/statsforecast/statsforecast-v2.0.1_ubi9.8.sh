#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package          : statsforecast
# Version          : v2.0.1
# Source repo      : https://github.com/Nixtla/statsforecast.git
# Tested on        : UBI:9.8
# Language         : Python, C++
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Mohammed Sheikh <Mohammed.Sheikh1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------
PACKAGE_NAME=statsforecast
PACKAGE_VERSION=${1:-v2.0.1}
PACKAGE_URL=https://github.com/Nixtla/statsforecast.git
PACKAGE_DIR=statsforecast
WORK_DIR=$(pwd)

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH
export PYSPARK_PYTHON=$(which python3.12)
export PYSPARK_DRIVER_PYTHON=$(which python3.12)

# Installing System Dependencies
dnf install -y \
    git \
    wget \
    gcc \
    gcc-c++ \
    make \
    cmake \
    python3.12 \
    python3.12-devel \
    python3.12-pip \
    openblas-devel \
    atlas-devel \
    java-17-openjdk-devel

python3.12 -m pip install --no-cache-dir --upgrade pip setuptools wheel build "pybind11>=2.10" cython meson-python scikit-build-core cmake ninja packaging pytest

# clone the repository
git clone --depth 1 --branch ${PACKAGE_VERSION} --recurse-submodules ${PACKAGE_URL}

# Installing dev dependencies
cd statsforecast
if ! python3.12 -m pip install --prefer-binary --extra-index-url https://wheels.developerfirst.ibm.com/ppc64le/linux ".[dask,spark]"; then
    echo "------------------$PACKAGE_NAME:dependency_install_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_VERSION | GitHub | Fail | Dependency_Install_Fails"
    exit 1
fi

# pinning pandas to avoid higher pandas version being installed
if ! python3.12 -m pip install --force-reinstall --no-deps "pandas==2.2.3" \
     --extra-index-url https://wheels.developerfirst.ibm.com/ppc64le/linux; then
    echo "------------------$PACKAGE_NAME:dependency_install_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_VERSION | GitHub | Fail | Dependency_Install_Fails"
    exit 1
fi

# Validation / Test
if ! python3.12 -m pytest action_files/ \
    --ignore=action_files/test_efficiency.py \
    --ignore=action_files/test_ray.py \
    -v; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_VERSION | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_VERSION | GitHub | Pass | Install_and_Test_Success"
    exit 0
fi