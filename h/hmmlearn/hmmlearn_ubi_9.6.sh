#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : hmmlearn
# Version       : 0.3.3
# Source repo   : https://github.com/hmmlearn/hmmlearn
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Rosman Carino <rcarino@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex

# Variables
PACKAGE_NAME=hmmlearn
PACKAGE_VERSION=${1:-0.3.3}
PACKAGE_URL=https://github.com/hmmlearn/hmmlearn
PACKAGE_DIR=hmmlearn

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
SOURCE=Github

# Install system dependencies
yum install -y --disablerepo=rpmfusion* git python3 python3-devel \
    gcc-toolset-13 gcc-toolset-13-gcc-gfortran \
    make wget sudo openblas-devel

export PATH=$PATH:/usr/local/bin/
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:/opt/rh/gcc-toolset-13/root/usr/lib:${LD_LIBRARY_PATH}

# Install Python build and test dependencies.
# scipy and scikit-learn are built from source on ppc64le; openblas-devel
# (installed above) satisfies their BLAS/LAPACK requirement.
pip3 install setuptools setuptools_scm wheel "pybind11>=2.6.0" numpy
pip3 install meson meson-python ninja
pip3 install scipy scikit-learn pytest

# Clone the repo (or reuse existing directory)
if [ -d "$PACKAGE_DIR" ]; then
    cd "$PACKAGE_DIR" || exit
else
    if ! git clone "$PACKAGE_URL" "$PACKAGE_DIR"; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Clone_Fails"
        exit 1
    fi
    cd "$PACKAGE_DIR" || exit
    git checkout "$PACKAGE_VERSION" || exit
fi

# Patch hmmlearn/utils.py for NumPy >= 2.5 compatibility.
# NumPy 2.5 deprecated in-place shape assignment (array.shape = new_shape);
# replace it with np.reshape() which works on all supported NumPy versions.
sed -i 's/a_sum\.shape = shape/a_sum = a_sum.reshape(shape)/g' src/hmmlearn/utils.py

# Patch setup.py: add -U_GLIBCXX_ASSERTIONS to suppress the _ZSt21__glibcxx_assert_fail
# symbol. The system Python on RHEL 9 is built with -D_GLIBCXX_ASSERTIONS which
# propagates to all C extensions; this symbol is absent from the system libstdc++ (GCC 11).
sed -i 's/Pybind11Extension("hmmlearn._hmmc", \["ext\/_hmmc.cpp"\], cxx_std=11)/Pybind11Extension("hmmlearn._hmmc", ["ext\/_hmmc.cpp"], cxx_std=11, extra_compile_args=["-U_GLIBCXX_ASSERTIONS"])/' setup.py

# Pin the version string so setuptools_scm does not append git-dirty metadata
# (the sed patch above makes the working tree dirty, which would otherwise
# produce a wheel name like hmmlearn-0.3.3.post0+g<hash>.d<date>...).
export SETUPTOOLS_SCM_PRETEND_VERSION="$PACKAGE_VERSION"

# Install the package (builds pybind11 C++ extension _hmmc)
if ! python3 -m pip install ./; then
    echo "------------------$PACKAGE_NAME:install_fails------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_Failed"
    exit 1
fi

# Run tests
if ! python3 -m pytest --pyargs hmmlearn.tests; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Pass | Both_Install_and_Test_Success"
    exit 0
fi