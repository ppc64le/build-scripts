#!/bin/bash

# -----------------------------------------------------------------------------
#
# Package          : opencv-python
# Version          : 84
#
# Source repo      : https://github.com/opencv/opencv-python.git
# Tested on        : UBI 9.3
# Language         : Python, C++
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

PACKAGE_NAME=opencv-python
PACKAGE_URL=https://github.com/opencv/opencv-python.git
PACKAGE_VERSION=${1:-84}
PYTHON_VER=${PYTHON_VERSION:-3.11}
OPENCV_PATCH_COMMIT=97f3f39

# Set to 1 to build the headless version
ENABLE_HEADLESS=${ENABLE_HEADLESS:-0}

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

# Dependencies
dnf groupinstall -y "Development Tools"
dnf install -y https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-9.0-24.el9.noarch.rpm \
    https://mirror.stream.centos.org/9-stream/BaseOS/`arch`/os/Packages/centos-stream-repos-9.0-24.el9.noarch.rpm \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/`arch`/os
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/`arch`/os
dnf config-manager --set-enabled crb
dnf install -y \
    cmake \
    gcc \
    sudo \
    gcc-c++ \
    git \
    python${PYTHON_VER} \
    python${PYTHON_VER}-devel \
    python${PYTHON_VER}-pip


# Cloning the repository from remote to local
if [ -z $PACKAGE_SOURCE_DIR ]; then
  git clone $PACKAGE_URL
  cd $PACKAGE_NAME  
else  
  cd $PACKAGE_SOURCE_DIR
fi

git checkout ${PACKAGE_VERSION}
git submodule update --init --recursive

# Apply patch only if PACKAGE_VERSION is 86
if [ "$PACKAGE_VERSION" == "86" ]; then

    # Move into the opencv submodule
    cd opencv

    echo "Applying POWER patch: $OPENCV_PATCH_COMMIT"
    git config --global user.email "Puneet.Sharma21@ibm.com"
    git config --global user.name "puneetsharma21"

    # Try cherry-picking the commit
    git cherry-pick "$OPENCV_PATCH_COMMIT"
    echo "cherry-pick applied."
    cd ..
    git add opencv
    git commit -m "Applied POWER patch: $OPENCV_PATCH_COMMIT"
else
    echo "Skipping patch: Not applicable for PACKAGE_VERSION=$PACKAGE_VERSION"
fi


# Update `pyproject.toml` to ensure compatibility
sed -i "/\"setuptools==59.2.0\"/c\  \"setuptools==59.2.0; python_version<'3.12'\",\n  \"setuptools<70.0.0; python_version>='3.12'\"" pyproject.toml


# Install necessary Python build tools
python${PYTHON_VER} -m pip install --upgrade pip numpy scikit-build cmake

# Get the NumPy include path
NUMPY_INCLUDE_PATH=$(python${PYTHON_VER} -c "import numpy; print(numpy.get_include())")

# Export CMAKE_ARGS
export CMAKE_ARGS="-D PYTHON3_NUMPY_INCLUDE_DIRS=${NUMPY_INCLUDE_PATH}"

echo "CMAKE_ARGS set to: ${CMAKE_ARGS}"

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

# Check if OpenCV is installed and run the test for headless mode if enabled
if [ "$ENABLE_HEADLESS" -eq 1 ]; then
    # Check for headless mode only if ENABLE_HEADLESS is set to 1
    if ! python${PYTHON_VER} -c "
import cv2
build_info = cv2.getBuildInformation()
if 'HAVE_OPENGL' not in build_info and 'HAVE_QT' not in build_info and 'HAVE_GTK' not in build_info:
    print('Headless mode: GUI features are disabled.')
"; then
        echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Build_success_but_test_fails"
        exit 1
    else
        echo "------------------$PACKAGE_NAME:both_build_and_test_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Build_and_Test_Success"
    fi
else
    # Verify OpenCV installation
    if ! python${PYTHON_VER} -c "import cv2; print('OpenCV is installed.')"; then
        echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Build_success_but_test_fails"
        exit 1
    else
        echo "------------------$PACKAGE_NAME:both_build_and_test_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Build_and_Test_Success"
    fi
fi

