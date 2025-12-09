#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : catboost
# Version       : v1.2.5
# Source repo   : https://github.com/catboost/catboost.git
# Tested on     : UBI:9.3
# Language      : Python,c,c++
# Ci-Check  : True
# Script License: Apache License Version 2.0
# Maintainer    : Pratik Tonage <Pratik.Tonage@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=catboost
PACKAGE_VERSION=${1:-v1.2.5}
PACKAGE_URL=https://github.com/catboost/catboost.git
BUILD_HOME=$(pwd)
PYTHON_VERSION=3.11.5
CMAKE_VERSION=3.28.1
CLANG_VERSION=17.0.6
export PATH=/usr/local/bin:/usr/bin:$PATH

#Install Centos repos and dependencies
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream//ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os
rpm --import http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official

yum install -y wget unzip zip git gcc-c++ zlib-devel openssl-devel libffi-devel sqlite-devel xz-devel perl ninja-build gfortran bzip2-devel xz lld libjpeg-turbo-devel openblas-devel texinfo clang-17.0.6

#Install Python from source
cd $BUILD_HOME
if [ -z "$(ls -A $BUILD_HOME/Python-${PYTHON_VERSION})" ]; then
    wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz
    tar xzf Python-${PYTHON_VERSION}.tgz
    rm -rf Python-${PYTHON_VERSION}.tgz 
    cd Python-${PYTHON_VERSION}
    ./configure --with-system-ffi --with-computed-gotos --enable-loadable-sqlite-extensions
    make -j ${nproc} 
else
    cd Python-${PYTHON_VERSION}
fi
make altinstall
ln -sf $(which python3.11) /usr/bin/python3
ln -sf $(which pip3.11) /usr/bin/pip3
python3 -V && pip3 -V
	
#Install cmake
cd $BUILD_HOME
if [ -z "$(ls -A $BUILD_HOME/cmake-${CMAKE_VERSION})" ]; then
    wget -c https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz
    tar -zxvf cmake-${CMAKE_VERSION}.tar.gz
    rm -rf cmake-${CMAKE_VERSION}.tar.gz
    cd cmake-${CMAKE_VERSION}
    ./bootstrap --prefix=/usr/local/cmake --parallel=2 -- -DBUILD_TESTING:BOOL=OFF -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_USE_OPENSSL:BOOL=ON
else
    cd cmake-${CMAKE_VERSION}
fi
make install -j$(nproc)
export PATH=/usr/local/cmake/bin:$PATH
cmake --version

#Setup clang
cd $BUILD_HOME
if [ "$(command -v clang)" ]; then
    echo "Clang is already installed at $(which clang)."
else
    wget https://github.com/llvm/llvm-project/releases/download/llvmorg-$CLANG_VERSION/clang+llvm-$CLANG_VERSION-powerpc64le-linux-rhel-8.8.tar.xz
    tar -xvf clang+llvm-$CLANG_VERSION-powerpc64le-linux-rhel-8.8.tar.xz
    rm -rf clang+llvm-$CLANG_VERSION-powerpc64le-linux-rhel-8.8.tar.xz
    mv clang+llvm-$CLANG_VERSION-powerpc64le-linux-rhel-8.8 clang-$CLANG_VERSION
    export PATH=$BUILD_HOME/clang-$CLANG_VERSION/bin:$PATH
    export CC=$BUILD_HOME/clang-$CLANG_VERSION/bin/clang
    export CXX=$BUILD_HOME/clang-$CLANG_VERSION/bin/clang++
    export ASM=$BUILD_HOME/clang-$CLANG_VERSION/bin/clang
    clang --version
fi 

#Clone the repository 	
cd $BUILD_HOME
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

pip3 install six setuptools wheel jupyterlab Pillow pandas conan==1.62.0 plotly scipy testpath pytest ipywidgets 'numpy<2.0'
conan install . || true && sed -i 's/ autotools.configure()/ autotools.configure(args=["--build=powerpc64le-linux-gnu"])/g' /$BUILD_HOME/root/.conan/data/yasm/1.3.0/_/_/export/conanfile.py

cd catboost/python-package/
#Build wheel
#Here we have skipped CatBoost visualization widget as it has dependency on @jupyterlab/builder@^4.2.3 and 4.x is not supported yet(https://github.com/catboost/catboost/issues/2533)
ret=0
python3 setup.py bdist_wheel --no-widget || ret=$?
if [ "$ret" -ne 0 ]
then
    exit 1
fi

#wheel will be generated in dist directory
#pip3 install <path-to-wheel>
pip3 install /catboost/catboost/python-package/dist/catboost-*_ppc64le.whl

#Run catboost python-package test
mkdir test_output
export CMAKE_SOURCE_DIR=/catboost
export CMAKE_BINARY_DIR=/catboost/catboost/python-package/build
export TEST_OUTPUT_DIR=/catboost/catboost/python-package/test_output

cd ut/medium/
python3 -m pytest || ret=$?
if [ "$ret" -ne 0 ]
then
    exit 2
fi

#conclude
echo "Build and test successful!"
echo "Wheel located at:"
CATBOOST_WHEEL=$(ls $BUILD_HOME/catboost/catboost/python-package/dist/catboost-*_ppc64le.whl)
echo "${CATBOOST_WHEEL}"
