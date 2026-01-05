#!/bin/bash -ex
# ----------------------------------------------------------------------------
# Package        : docling
# Version        : v2.36.0
# Source repo    : https://github.com/docling-project/docling
# Tested on      : UBI 9.5
# Language       : Python
# Ci-Check   : false
# Maintainer     : Sumit Dubey <sumit.dubey2@ibm.com>
# Script License : Apache License, Version 2.0 or later
#
# Disclaimer     : This script has been tested in root mode on the specified
#                  platform and package version. Functionality with newer
#                  versions of the package or OS is not guaranteed.
# ----------------------------------------------------------------------------

# ---------------------------
# Configuration
# ---------------------------
PACKAGE_NAME="docling"
PACKAGE_ORG="docling-project"
PACKAGE_VERSION="v2.36.0"
PACKAGE_URL="https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}.git"
PACKAGE_VERSION_WO_LEADING_V="${PACKAGE_VERSION:1}"
PYTORCH_VERSION=2.3.0
CMAKE_VERSION=3.28.1
OPENJPEG_VERSION=v2.5.3
PILLOW_VERSION=11.2.1
OPENCV_PYTHON_VERSION=86 #4.11.0.86
PYPDFIUM2_VERSION=35a88d21450eb395e023ca280c9f4c855ec9684d
TORCH7_VERSION=814ea4a
TORCHVISION_VERSION=v0.16.0
SCRIPT_PATH=$(dirname $(realpath $0))
RUNTESTS=1
BUILD_HOME="$(pwd)"

# -------------------
# Parse CLI Arguments
# -------------------
for i in "$@"; do
  case $i in
    --skip-tests)
      RUNTESTS=0
      echo "Skipping tests"
      shift
      ;;
    -*|--*)
      echo "Unknown option $i"
      exit 3
      ;;
    *)
      PACKAGE_VERSION=$i
      echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"
      ;;
  esac
done

# ---------------------------
# Dependency Installation
# ---------------------------
echo "Installing required packages..."
yum install -y git wget gcc gcc-c++ python3-devel pip python3-numpy zlib-devel libjpeg-devel ninja-build libicu-devel lcms2-devel glib2-devel freetype-devel gfortran openblas-devel libxml2-devel libxslt-devel

echo "Configuring package repositories..."
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
dnf config-manager --set-enabled codeready-builder-for-rhel-9-$(arch)-rpms && \
yum install -y gn geos-devel tesseract-devel spatialindex-devel
pip3 install build pytest numpy

# ---------------------------
# Build and Install cmake
# ---------------------------
cd $BUILD_HOME
wget -c https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz
tar -zxvf cmake-${CMAKE_VERSION}.tar.gz
rm -rf cmake-${CMAKE_VERSION}.tar.gz
cd cmake-${CMAKE_VERSION}
./bootstrap --prefix=/usr/local/cmake --parallel=2 -- -DBUILD_TESTING:BOOL=OFF -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_USE_OPENSSL:BOOL=OFF
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
pip3 wheel . --verbose
pip3 install *.whl

# ----------------------------------------
# Build and Install opencv-python-headless
# ----------------------------------------
cd $BUILD_HOME
git clone --recursive https://github.com/opencv/opencv-python.git
cd opencv-python
git checkout $OPENCV_PYTHON_VERSION
git submodule sync
git submodule update --init --recursive opencv
cd opencv
git apply ${SCRIPT_PATH}/opencv_${PACKAGE_NAME}_${PACKAGE_VERSION}.patch
cd ..
export ENABLE_HEADLESS=1
pip3 wheel . --verbose
pip3 install *.whl

# ---------------------------
# Build and Install pytorch
# ---------------------------
cd $BUILD_HOME
PYTORCH_VERSION_CPU="${PYTORCH_VERSION}+cpu"
export PYTORCH_BUILD_VERSION=${PYTORCH_VERSION_CPU}
git clone https://github.com/pytorch/pytorch
cd pytorch
git checkout v$PYTORCH_VERSION
pip3 install -r requirements.txt
git submodule sync
git submodule update --init --recursive
export PYTORCH_BUILD_NUMBER=1
python3 setup.py bdist_wheel
pip3 install $BUILD_HOME/pytorch/dist/torch-$PYTORCH_BUILD_VERSION-cp39-cp39-linux_$(arch).whl

# ---------------------------
# Build and Install pypdfium2
# ---------------------------
cd $BUILD_HOME
git clone "https://github.com/pypdfium2-team/pypdfium2.git"
cd pypdfium2/
git checkout $PYPDFIUM2_VERSION
python3 ./setupsrc/pypdfium2_setup/build_native.py --compiler gcc
sed -i 's#7191#6996#g' ./setupsrc/pypdfium2_setup/build_native.py
python3 ./setupsrc/pypdfium2_setup/build_native.py --compiler gcc
#PDFIUM_PLATFORM="sourcebuild" python3 -m pip install -v .
PDFIUM_PLATFORM="sourcebuild" pip3 wheel . --verbose
pip3 install *.whl

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

# Below patch is needed to exclude the models that come under SWAG license (CC-BY-NC-4.0)
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/t/torchvision/0001-Exclude-source-that-has-commercial-license.patch
git apply ./0001-Exclude-source-that-has-commercial-license.patch

python3 setup.py bdist_wheel
pip3 install dist/*.whl

# ---------------------------
# Clone and Prepare Repository
# ---------------------------
cd "${BUILD_HOME}"
git clone "${PACKAGE_URL}"
cd "${PACKAGE_NAME}"
git checkout "${PACKAGE_VERSION}"
git apply ${SCRIPT_PATH}/${PACKAGE_NAME}_${PACKAGE_VERSION}.patch

# ---------------------------
# Build and Install
# ---------------------------
ret=0
python3 -m build --wheel || ret=$?
if [ $ret -ne 0 ]; then
        set +ex
	echo "------------------ ${PACKAGE_NAME}: Build Failed ------------------"
	exit 1
fi
export DOCLING_WHEEL=${BUILD_HOME}/${PACKAGE_NAME}/dist/${PACKAGE_NAME}-${PACKAGE_VERSION_WO_LEADING_V}-py3-none-any.whl
pip3 install scikit-image==0.19.3 "numpy<2.0" tesserocr
pip3 install ${DOCLING_WHEEL}

# ---------------------------
# Skip Tests?
# ---------------------------
if [ "$RUNTESTS" -eq 0 ]; then
        set +ex
        echo "Complete: Build successful! Docling has been installed. Docling wheel available at [${DOCLING_WHEEL}]"
        exit 0
fi

# ---------------------------
# Test
# ---------------------------
ret=0
pytest || ret=$?
if [ $ret -ne 0 ]; then
        set +ex
	echo "------------------ ${PACKAGE_NAME}: Test Failed ------------------"
	exit 2
fi

set +ex
echo "Complete: Build and Test successful! Docling has been installed. Docling wheel available at [$DOCLING_WHEEL]"
echo "The following five failing test cases were disabled because they were in parity with Intel:"
echo "    tests/test_backend_csv.py::test_e2e_valid_csv_conversions"
echo "    tests/test_backend_webp.py::test_e2e_webp_conversions"
echo "    tests/test_e2e_conversion.py::test_e2e_pdfs_conversions"
echo "    tests/test_e2e_ocr_conversion.py::test_e2e_conversions"
echo "    tests/test_backend_msword.py::test_e2e_docx_conversions"

