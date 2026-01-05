#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : docling-serve
# Version          : v1.9.0
# Source repo      : https://github.com/docling-project/docling-serve.git
# Tested on        : UBI 9.6
# Language         : Python
# Ci-Check         : True
# Script License   : MIT License
# Maintainer       : Haritha Nagothu <haritha.nagothu2@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_DIR="docling-serve"
PACKAGE_VERSION="v1.9.0"
PACKAGE_URL="https://github.com/docling-project/docling-serve.git"
PACKAGE_VERSION_WO_LEADING_V="${PACKAGE_VERSION:1}"
CMAKE_VERSION=3.28.1
OPENJPEG_VERSION=v2.5.3
PILLOW_VERSION=11.2.1
OPENCV_PYTHON_VERSION=86 #4.11.0.86
PYPDFIUM2_VERSION=35a88d21450eb395e023ca280c9f4c855ec9684d
TORCH7_VERSION=814ea4a
TORCHVISION_VERSION=v0.16.0
TREE_SITTER_VERSION=v0.23.2
ABSEIL_VERSION=20230802.2
SCRIPT_PATH=$(dirname $(realpath $0))
RUNTESTS=1
BUILD_HOME="$(pwd)"


yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os
        yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream//ppc64le/os
        yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os
        rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official-SHA256
				
rpm -e --nodeps openssl-fips-provider-so-3.0.7-6.el9_5.ppc64le


echo "Installing required packages..."
yum install -y git wget gcc gcc-c++  python3.12-devel python3.12-pip zlib-devel libjpeg-devel ninja-build libicu-devel lcms2-devel glib2-devel freetype-devel gfortran openblas-devel libxml2-devel libxslt-devel ncurses-devel gn libtiff-devel spatialindex-devel rust cargo llvm16-devel geos-devel tesseract-devel ffmpeg-free ffmpeg-free-devel
export LLVM_CONFIG=/usr/lib64/llvm16/bin/llvm-config
python3.12 -m pip install build pytest numpy wheel

# ---------------------------
# Build and Install cmake
# ---------------------------

if [ -z "$(ls -A $BUILD_HOME/cmake-${CMAKE_VERSION})" ]; then
	wget -c https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz
	tar -zxvf cmake-${CMAKE_VERSION}.tar.gz
	rm -rf cmake-${CMAKE_VERSION}.tar.gz
	cd cmake-${CMAKE_VERSION}
	./bootstrap --prefix=/usr/local/cmake --parallel=2 -- -DBUILD_TESTING:BOOL=OFF -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_USE_OPENSSL:BOOL=OFF
else
	cd cmake-${CMAKE_VERSION}
fi
make install -j$(nproc)
export PATH=/usr/local/cmake/bin:$PATH
cmake --version

# ---------------------------
# Build and Install openjpeg
# ---------------------------
#rpm -e --nodeps openjpeg2
cd $BUILD_HOME
git clone "https://github.com/uclouvain/openjpeg.git"
cd openjpeg/
git checkout $OPENJPEG_VERSION
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
make install
export LD_LIBRARY_PATH=/usr/local/lib64:$LD_LIBRARY_PATH
ldconfig


# ---------------------------
# Build and Install pillow
# ---------------------------
cd $BUILD_HOME
git clone https://github.com/python-pillow/Pillow
cd Pillow
git checkout $PILLOW_VERSION
python3.12 -m pip wheel . --verbose
python3.12 -m pip install *.whl


# ----------------------------------------
# Build and Install opencv-python
# ----------------------------------------
cd $BUILD_HOME
if [ -z "$(ls -A $BUILD_HOME/opencv-python)" ]; then
	git clone --recursive https://github.com/opencv/opencv-python.git
	cd opencv-python
	git checkout $OPENCV_PYTHON_VERSION
	git submodule sync
	git submodule update --init --recursive opencv
	cd opencv
	wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/d/docling/opencv_docling_v2.60.1.patch
    git apply opencv_docling_v2.60.1.patch
	cd ..
	export ENABLE_HEADLESS=1
	python3.12 -m pip wheel . --verbose
else
	cd opencv-python
fi
python3.12 -m pip install *.whl


#Install Torch
python3.12 -m pip install --prefer-binary torch==2.5.1 --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux

#Install libprotobuf 
python3.12 -m pip install --prefer-binary libprotobuf==4.25.3 --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux

export LD_LIBRARY_PATH=/usr/local/lib/python3.12/site-packages/libprotobuf/lib64/:$LD_LIBRARY_PATH

# ---------------------------
# Build and Install pypdfium2
# ---------------------------
cd $BUILD_HOME
git clone "https://github.com/pypdfium2-team/pypdfium2.git"
cd pypdfium2/
git checkout $PYPDFIUM2_VERSION
python3.12  ./setupsrc/pypdfium2_setup/build_native.py --compiler gcc
sed -i 's#7191#6996#g' ./setupsrc/pypdfium2_setup/build_native.py
python3.12 ./setupsrc/pypdfium2_setup/build_native.py --compiler gcc
#PDFIUM_PLATFORM="sourcebuild" python3.12 -m pip install -v .
PDFIUM_PLATFORM="sourcebuild" python3.12 -m pip wheel . --verbose
python3.12 -m pip install *.whl

# ---------------------------
# Build and Install TH
# ---------------------------
cd $BUILD_HOME
git clone https://github.com/torch/torch7
cd torch7
git checkout $TORCH7_VERSION
mkdir th_build
cd th_build
cmake ../lib/TH
make
make install

# ------------------------------
# Build and Install torchvision
# ------------------------------
cd $BUILD_HOME
git clone https://github.com/pytorch/vision.git
cd vision
git checkout $TORCHVISION_VERSION
python3.12 setup.py bdist_wheel
python3.12 -m pip install dist/*.whl

# -------------------------------------
# Build and Install tree-sitter headers
# -------------------------------------
cd $BUILD_HOME
git clone https://github.com/tree-sitter/tree-sitter-c
cd tree-sitter-c
git checkout $TREE_SITTER_VERSION
mkdir -p /usr/include/tree_sitter/
cp src/tree_sitter/*.h /usr/include/tree_sitter/

# -----------------------------
# Build and Install abseil-cpp
# -----------------------------
cd $BUILD_HOME
git clone https://github.com/abseil/abseil-cpp
cd abseil-cpp
git checkout $ABSEIL_VERSION
mkdir build
cd build
cmake -DBUILD_SHARED_LIBS=ON -DABSL_BUILD_TESTING=OFF ..
make install
ldconfig

# ---------------------------
# Build and Install Docling
# ---------------------------
cd ${BUILD_HOME}
git clone https://github.com/docling-project/docling.git
cd docling
git checkout v2.60.1
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/d/docling/docling_v2.60.1.patch
git apply docling_v2.60.1.patch
python3.12 -m build --wheel
export DOCLING_WHEEL=dist/docling-2.60.1-py3-none-any.whl

#Install docling wheel and its dependencies
python3.12 -m pip install wheel==0.45.1 hf_xet==1.2.0 huggingface_hub==1.1.4 pytest-asyncio==1.2.0 pytest_check pytest_asyncio asgi_lifespan
python3.12 -m pip install --prefer-binary --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux/ \
        tree-sitter-python==0.23.2 tree_sitter_c==0.23.2 "numpy<2.0" tesserocr==2.9.1 openai-whisper==20230117 ${DOCLING_WHEEL}

python3.12 -m pip install --prefer-binary pyarrow==19.0.0 --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux
python3.12 -m pip install --prefer-binary av==13.1.0 --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux
python3.12 -m pip install git+https://github.com/tree-sitter/tree-sitter-typescript.git

# ---------------------------
# Build and Install Docling-serve
# ---------------------------

cd $BUILD_HOME
git clone $PACKAGE_URL
cd  $PACKAGE_DIR
git checkout $PACKAGE_VERSION

if ! (python3.12 -m pip install .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_DIR"
    echo "$PACKAGE_DIR  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:Install_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_DIR"
    echo "$PACKAGE_DIR  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Install_Success"
    exit 0
fi

# Skipping tests that fetch external URLs (fail with httpx.ConnectError due to no network access).
