#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : re2
# Version       : 2025-11-05
# Source repo   : https://github.com/google/re2.git
# Tested on     : UBI 9.3
# Language      : c
# Ci-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Shivansh Sharma <Shivansh.s1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_NAME=re2
PACKAGE_VERSION=${1:-2025-11-05}
PACKAGE_URL=https://github.com/google/re2.git
CURRENT_DIR=$(pwd)
PACKAGE_DIR=re2

echo "------------------------Installing dependencies-------------------"
yum install -y wget

# install core dependencies
yum install -y python python-pip python-devel  gcc-toolset-13 gcc-toolset-13-binutils gcc-toolset-13-binutils-devel gcc-toolset-13-gcc-c++ git make cmake binutils

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
gcc --version

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

python -m pip install --upgrade pip
pip install ninja setuptools

export CC=$(which gcc)
export CXX=$(which g++)
export GCC=$CC
export GXX=$CXX


#Build abseil-cpp from source
cd $CURRENT_DIR
git clone https://github.com/abseil/abseil-cpp
cd abseil-cpp
git checkout 20240116.2

mkdir build
cd build

cmake -G Ninja \
    ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_PREFIX=${ABSEIL_PREFIX} \
    -DBUILD_SHARED_LIBS=ON \
    -DABSL_PROPAGATE_CXX_STD=ON \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
   ..

cmake --build .
cmake --install .
export LD_LIBRARY_PATH=${ABSEIL_PREFIX}/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=${ABSEIL_PREFIX}/lib/pkgconfig:$PKG_CONFIG_PATH
export CPLUS_INCLUDE_PATH=${ABSEIL_PREFIX}/include:$CPLUS_INCLUDE_PATH
export C_INCLUDE_PATH=${ABSEIL_PREFIX}/include:$C_INCLUDE_PATH



# clone source repository
cd $CURRENT_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init


mkdir prefix
export PREFIX=$(pwd)/prefix
make -j$(nproc)
make install prefix=$PREFIX


# Headers
export CPLUS_INCLUDE_PATH=${CURRENT_DIR}/${PACKAGE_NAME}/prefix/include:$CPLUS_INCLUDE_PATH
export C_INCLUDE_PATH=${CURRENT_DIR}/${PACKAGE_NAME}/prefix/include:$C_INCLUDE_PATH
export LD_LIBRARY_PATH=${CURRENT_DIR}/${PACKAGE_NAME}/prefix/lib:$LD_LIBRARY_PATH
export LIBRARY_PATH=${CURRENT_DIR}/${PACKAGE_NAME}/prefix/lib:$LIBRARY_PATH


#During wheel creation for this package we need exported cmake-args. Once script get exit, and if we build wheel through wrapper script, then those are not applicable during wheel creation. So we are generating wheel for this package in script itself.
echo "---------------------------------------------------Building the wheel--------------------------------------------------"
pip install --upgrade pip build setuptools wheel pybind11

cd python
sed -i "/os.makedirs(PACKAGE)/a\
\\
    # Vendor libre2.so into the Python package\\
    libdir = os.path.join(PACKAGE, 'lib')\\
    libpath = os.path.abspath('../prefix/lib')\\
    shutil.copytree(libpath, libdir)\
" setup.py

sed -i "s/name='google-re2'/name='re2'/" setup.py

sed -i "/packages=\\[PACKAGE\\],/a\
\\
      package_data={PACKAGE: ['lib/*']},\
" setup.py


python setup.py bdist_wheel 
python -m pip install dist/re2-*

echo "----------------------------------------------Testing pkg-------------------------------------------------------"
#Test package
if ! (python -c "import re2") ; then
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
