#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : matplotlib
# Version       : v3.9.2
# Source repo   : https://github.com/matplotlib/matplotlib.git
# Tested on     : UBI 9.3
# Language      : Python, C++, Jupyter Notebook
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Chandan.Abhyankar@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=matplotlib
PACKAGE_VERSION=${1:-v3.9.2}
PACKAGE_URL=https://github.com/matplotlib/matplotlib.git
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)
PYTHON_VER=${2:-3.11}

dnf install -y https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-9.0-24.el9.noarch.rpm \
            https://mirror.stream.centos.org/9-stream/BaseOS/`arch`/os/Packages/centos-stream-repos-9.0-24.el9.noarch.rpm \
                        https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/`arch`/os
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/`arch`/os
dnf config-manager --set-enabled crb
dnf install -y git g++ ninja-build pybind11-devel \
    libtiff-devel libjpeg-devel openjpeg2-devel zlib-devel \
    freetype-devel lcms2-devel libwebp-devel tcl-devel tk-devel \
    harfbuzz-devel fribidi-devel libraqm-devel libimagequant-devel libxcb-devel \
    python${PYTHON_VER}-devel python${PYTHON_VER}-pip python${PYTHON_VER}-setuptools python${PYTHON_VER}-wheel

if ! command -v pip; then
    ln -s $(command -v pip${PYTHON_VER}) /usr/bin/pip
fi
if ! command -v python; then
    ln -s $(command -v python${PYTHON_VER}) /usr/bin/python
fi


# A virtual environment is needed as Maplotlib builds with meson build system
# Meson picks python3 (/usr/bin/python3 -> python3.9) on UBI9
# Virtual env sets python3 -> python$PYTHON_VER and adds it in PATH
python -m venv .venv
source .venv/bin/activate

pip install -U contourpy cycler fonttools kiwisolver meson meson-python \
    numpy packaging pillow pybind11 pyparsing pyproject-metadata python-dateutil setuptools-scm six


if ! pip install -v matplotlib==${PACKAGE_VERSION:1} --no-build-isolation; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! python -c "import matplotlib; print(matplotlib.__file__)"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi

deactivate
