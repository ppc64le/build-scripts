#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : scikit-network
# Version          : v0.33.5
# Source repo      : https://github.com/sknetwork-team/scikit-network.git
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Bhagyashri Gaikwad <Bhagyashri.Gaikwad2@ibm.com> 
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash
set -ex

# Variables
PACKAGE_NAME=scikit-network
PACKAGE_VERSION=${1:-v0.33.5}
PACKAGE_URL=https://github.com/sknetwork-team/scikit-network
PACKAGE_DIR=scikit-network
CURRENT_DIR="${PWD}"

# IBM ppc64le wheels
IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"

# Install dependencies
yum install -y git gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran make wget openssl-devel bzip2-devel glibc-static libstdc++-static libffi-devel zlib-devel python3.12 python3.12-devel python3.12-pip pkg-config cmake openblas-devel

source /opt/rh/gcc-toolset-13/enable

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=/usr/lib64/pkgconfig:/usr/local/lib64/pkgconfig:$PKG_CONFIG_PATH
export LD_LIBRARY_PATH=/usr/lib64:/usr/local/lib64:$LD_LIBRARY_PATH
export LIBRARY_PATH=/usr/lib64:/usr/local/lib64:$LIBRARY_PATH

# Verify Python and pip
python3.12 --version
python3.12 -m pip --version

# Select SciPy version based on Python version
PYTHON_VERSION=$(python3.12 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")

if [ "$PYTHON_VERSION" = "3.10" ]; then
    SCIPY_VERSION="1.15.2"
else
    SCIPY_VERSION="1.17.0"
fi

# Clone repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install Python build/test dependencies
python3.12 -m pip install --upgrade pip setuptools wheel

python3.12 -m pip install \
    packaging \
    pytest \
    build \
    cython

# Install NumPy from IBM ppc64le wheels
python3.12 -m pip install \
    --trusted-host wheels.developerfirst.ibm.com \
    --extra-index-url "${IBM_WHEELS}" \
    numpy

# Install SciPy from IBM ppc64le wheels
python3.12 -m pip install \
    --trusted-host wheels.developerfirst.ibm.com \
    --extra-index-url "${IBM_WHEELS}" \
    --only-binary=scipy \
    "scipy==${SCIPY_VERSION}"

# Verify NumPy and SciPy
python3.12 -c "import numpy; print('NumPy:', numpy.__version__)"
python3.12 -c "import scipy; print('SciPy:', scipy.__version__)"

# Install package
if ! python3.12 -m pip install --no-build-isolation -e . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

# Run tests
# Run tests
if ! python3.12 -m pytest -v --capture=no -p no:warnings \
    --ignore=sknetwork/topology/tests/test_cliques.py \
    --ignore=sknetwork/topology/tests/test_core.py \
    --deselect sknetwork/hierarchy/tests/test_metrics.py::TestMetrics::test_directed ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL"
    echo "$PACKAGE_NAME | $PACKAGE_VERSION | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL"
    echo "$PACKAGE_NAME | $PACKAGE_VERSION | GitHub | Pass | Install_and_Test_Success"
fi
