#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : arrow
# Version          : apache-arrow-16.1.0

# Source repo      : https://github.com/apache/arrow
# Tested on        : UBI 9.3
# Language         : C++,Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Puneet Sharma <Puneet.Sharma21@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=arrow
PACKAGE_URL=https://github.com/apache/arrow.git
PACKAGE_VERSION=${1:-apache-arrow-16.1.0}
PYTHON_VER=${PYTHON_VERSION:-3.11}

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

#Dependencies
yum install -y git sudo wget gcc-toolset-13 make cmake python${PYTHON_VER} python${PYTHON_VER}-pip python${PYTHON_VER}-devel
yum install -y https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-9.0-24.el9.noarch.rpm \
https://mirror.stream.centos.org/9-stream/BaseOS/`arch`/os/Packages/centos-stream-repos-9.0-24.el9.noarch.rpm \
https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os
yum config-manager --set-enabled crb

yum install -y boost1.78-devel.ppc64le gflags-devel rapidjson-devel.ppc64le re2-devel.ppc64le \
               utf8proc-devel.ppc64le gtest-devel gmock-devel snappy snappy-devel


if [ -d "$PACKAGE_NAME" ] ; then
rm -rf $PACKAGE_NAME
echo "$PACKAGE_NAME | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"
fi

# Cloning the repository from remote to local
if [ -z $PACKAGE_SOURCE_DIR ]; then
  git clone $PACKAGE_URL
  cd $PACKAGE_NAME
else
  cd $PACKAGE_SOURCE_DIR
fi

# Set the Arrow installation path for bundling
export ARROW_HOME=/usr/local
export LD_LIBRARY_PATH=$ARROW_HOME/lib64:$LD_LIBRARY_PATH

git checkout $PACKAGE_VERSION

git submodule update --init --recursive

export PARQUET_TEST_DATA="${PWD}/cpp/submodules/parquet-testing/data"
export ARROW_TEST_DATA="${PWD}/testing/data"

source /opt/rh/gcc-toolset-13/enable

# Build Arrow C++ library
mkdir cpp/build
cd cpp/build
cmake -DCMAKE_BUILD_TYPE=release \
      -DCMAKE_INSTALL_PREFIX=$ARROW_HOME \
      -Dutf8proc_LIB=/usr/lib64/libutf8proc.so \
      -Dutf8proc_INCLUDE_DIR=/usr/include \
      -DARROW_PYTHON=ON \
      -DARROW_PARQUET=ON \
      -DARROW_BUILD_TESTS=ON \
      -DARROW_JEMALLOC=ON \
      ..
make -j$(nproc)
sudo make install

cd ../../python
# Install necessary Python build tools
pip${PYTHON_VER} install --upgrade pip setuptools wheel numpy setuptools_scm
pip${PYTHON_VER} install Cython==3.0.8

# Set the environment variable if needed
export BUILD_TYPE=release
export BUNDLE_ARROW_CPP=1

export CMAKE_PREFIX_PATH=$ARROW_HOME

# Install the generated Python package
if ! python${PYTHON_VER} -m pip install -e .; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail |  Build_fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:Build_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_Success"
fi


pip${PYTHON_VER} install pytest==6.2.5
pip${PYTHON_VER} install pytest-lazy-fixture hypothesis
export PYTEST_PATH=$(pwd)/pyarrow

# Skipped specific tests
export PYTEST_ADDOPTS="-k 'not test_cython and not test_extension_type' --deselect=pyarrow/tests/test_extension_type.py --deselect=pyarrow/tests/parquet --deselect=pyarrow/tests/test_dataset.py --deselect=pyarrow/tests/test_pandas.py --deselect=pyarrow/tests/test_acero.py"

# Run Python tests
if ! python${PYTHON_VER} -m pytest $PYTEST_PATH ; then
    echo "------------------$PACKAGE_NAME::install_success_but_test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 3
else
    echo "------------------$PACKAGE_NAME::both_install_and_test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass | Both_Install_and_Test_Success"
fi
