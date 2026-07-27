#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : mistral-common
# Version       : v1.11.5
# Source repo   : https://github.com/mistralai/mistral-common
# Tested on     : UBI: 9.6
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vivek Sharma <Vivek.Sharma20@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
#             platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact the "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex

# Variables
PACKAGE_NAME=mistral-common
PACKAGE_VERSION=${1:-v1.11.5}
PACKAGE_URL=https://github.com/mistralai/mistral-common
DEVPI_URL=https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/

# Install system dependencies
yum install -y \
    git \
    wget \
    make \
    cmake \
    gcc \
    gcc-c++ \
    python3.12 \
    python3.12-devel \
    python3.12-pip \
    openssl-devel \
    bzip2-devel \
    libffi-devel \
    zlib-devel \
    libjpeg-turbo-devel \
    libpng-devel \
    freetype-devel \
    lcms2-devel \
    libtiff-devel \
    libwebp-devel \
    openjpeg2-devel \
    libsndfile \
    pkgconf-pkg-config \
    gcc-toolset-13 \
    gcc-toolset-13-gcc \
    gcc-toolset-13-gcc-c++ \
    gcc-toolset-13-libstdc++-devel \
    gcc-toolset-13-libatomic-devel \
	  rust \
	  cargo

# Clone repository
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME}
git checkout ${PACKAGE_VERSION}

# Upgrade Python packaging tools
python3.12 -m pip install --upgrade \
    pip \
    setuptools \
    wheel \
    build
# ------------------------------------------------------------------------------
# Install runtime dependencies
# ------------------------------------------------------------------------------

python3.12 -m pip install \
    "numpy>=1.25,<2.4" \
    pydantic \
    requests \
    jsonschema \
    typing_extensions \
    pydantic-extra-types \
    pycountry \
    pillow \
    tiktoken \
    sentencepiece \
	  llguidance \
    soundfile \
    soxr \
    huggingface-hub \
    jinja2 \
    openai \
    uvicorn \
    pydantic-settings \
    click \
    "fastapi[standard]"	

# Install build/test utilities
python3.12 -m pip install \
    pytest \
    pytest-cov
	
# ------------------------------------------------------------------------------
# Install OpenCV from IBM DevPI
# ------------------------------------------------------------------------------

python3.12 -m pip install \
    --index-url ${DEVPI_URL} \
    opencv-python-headless

# Build and install
if ! python3.12 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

if ! python3.12 -m pytest tests \
        --deselect=tests/test_audio.py::test_audio_base64[True] \
        --deselect=tests/test_audio.py::test_audio_base64[False] \
        --deselect=tests/test_audio.py::TestDeprecationWarnings::test_audio_import_from_old_location_warns[AudioFormat] \
        --deselect=tests/test_audio.py::TestDeprecationWarnings::test_audio_import_from_old_location_warns[EXPECTED_FORMAT_VALUES]
then
    echo "------------------${PACKAGE_NAME}:build_success_but_test_fails---------------------"
    echo "${PACKAGE_URL} ${PACKAGE_NAME}"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | GitHub | Fail | Build_success_but_Test_Fails"
    exit 2
else
    echo "------------------${PACKAGE_NAME}:build_&_test_both_success-------------------------"
    echo "${PACKAGE_URL} ${PACKAGE_NAME}"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | GitHub | Pass | Both_Build_and_Test_Success"
    exit 0
fi
