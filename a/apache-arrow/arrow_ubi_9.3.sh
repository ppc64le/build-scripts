#!/usr/bin/env bash
# -----------------------------------------------------------------
#
# Package	       : apache-arrow
# Version	       : apache-arrow-19.0.1
# Source repo	   : https://github.com/apache/arrow
# Tested on	       : UBI 9.3
# Language         : C++, python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer	   : Onkar Kubal <onkar.kubal@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e
PACKAGE_NAME=arrow
SCRIPT_PACKAGE_VERSION=main
PACKAGE_VERSION=apache-arrow-19.0.1
PACKAGE_URL=https://github.com/apache/arrow
SCRIPT_PATH=$(dirname $(realpath $0))
BUILD_HOME=$(pwd)
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)
PYTHON_VER=${2:-3.12}
ARROW_BUILD_TYPE=release

# Update and install dependencies
yum update -y && yum install -y wget git cmake clang ninja-build bzip2 gcc-toolset-13 python${PYTHON_VER}-devel python${PYTHON_VER}-wheel python${PYTHON_VER}-pip python${PYTHON_VER}-setuptools

# Install gcc 13
source /opt/rh/gcc-toolset-13/enable
gcc --version

if ! command -v python; then
    ln -s $(command -v python${PYTHON_VER}) /usr/bin/python
fi
if ! command -v pip; then
    ln -s $(command -v pip${PYTHON_VER}) /usr/bin/pip
fi

# Download arrow
git clone --recursive ${PACKAGE_URL} -b ${PACKAGE_VERSION}
git submodule update --init
export PARQUET_TEST_DATA="${PWD}/cpp/submodules/parquet-testing/data"
export ARROW_TEST_DATA="${PWD}/testing/data"
cd ..
# Build Arrow
python -m venv pyarrow-dev
source ./pyarrow-dev/bin/activate
pip install --upgrade pip
mkdir dist
export ARROW_HOME=$(pwd)/dist
export LD_LIBRARY_PATH=$(pwd)/dist/lib:$LD_LIBRARY_PATH
export CMAKE_PREFIX_PATH=$ARROW_HOME:$CMAKE_PREFIX_PATH

cmake -S arrow/cpp -B arrow/cpp/build \
        -DCMAKE_INSTALL_PREFIX=$ARROW_HOME \
        -DCMAKE_INSTALL_LIBDIR=lib \
        --preset ninja-release-python
cmake --build arrow/cpp/build --target install

cd $BUILD_HOME
cp $ARROW_HOME/lib/libarrow_substrait.so.1900 arrow/python/pyarrow
cp $ARROW_HOME/lib/libarrow_dataset.so.1900 arrow/python/pyarrow
cp $ARROW_HOME/lib/libparquet.so.1900 arrow/python/pyarrow
cp $ARROW_HOME/lib/libarrow_acero.so.1900 arrow/python/pyarrow
cp $ARROW_HOME/lib/libarrow.so.1900 arrow/python/pyarrow

# Build pyarrow
pushd arrow/python
# check if setup.py file is present
if [ -f "setup.py" ]; then
    echo "setup.py file exists"
    pip install -r requirements-build.txt
    pip install wheel
    export PYARROW_PARALLEL=4
    # Build the wheel file
    if ! python setup.py build_ext --build-type=$ARROW_BUILD_TYPE --bundle-arrow-cpp bdist_wheel ; then
        echo "------------------$PACKAGE_NAME:Build_wheel_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_wheel_Fails"
        exit 2
    else
        echo "------------------$PACKAGE_NAME:Build_wheel_success-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Success |  Build_wheel_Success"
	fi

	echo "Wheel Path"
    ls dist/*.whl
    # Install the package from the wheel
    if ! pip install dist/*.whl ; then
        echo "------------------$PACKAGE_NAME:Install_wheel_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_wheel_Fails"
        exit 2
    else
		echo "------------------$PACKAGE_NAME:Install_wheel_success-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Success |  Install_wheel_Success"
	fi
else
    echo "setup.py not present"
    exit 2
fi
popd

# Unit test
pushd arrow/python
git clean -Xfd .
pip install -r requirements-test.txt
python setup.py build_ext --inplace
pip install pytest wheel
if ! python -m pytest pyarrow ; then
    echo "------------------$PACKAGE_NAME:Test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Test_Success"
    exit 0
fi
popd