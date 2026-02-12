#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : javabridge
# Version          : master
# Source repo      : https://github.com/CellProfiler/python-javabridge
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e
# Variables
PACKAGE_NAME=javabridge
PACKAGE_VERSION=${1:-master}
PACKAGE_URL=https://github.com/LeeKamentsky/python-javabridge
PACKAGE_DIR=python-javabridge

CURRENT_DIR=${PWD}

yum install -y git make cmake zip tar wget \
    python3.12 python3.12-devel python3.12-pip \
    gcc-toolset-13 gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc \
    zlib-devel libjpeg-devel openssl openssl-devel \
    freetype-devel pkgconfig rust cargo diffutils \
    libyaml-devel openssh-server openssh-clients \
    java-11-openjdk java-11-openjdk-devel

source /opt/rh/gcc-toolset-13/enable

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$PATH:$JAVA_HOME/bin


cd $CURRENT_DIR
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

# ---- Python tooling ----
python3.12 -m pip install --upgrade pip
python3.12 -m pip install "cython<3" wheel setuptools
python3.12 -m pip install numpy

# ---- Build ----
#Editable installs use PEP517 isolation and ignore pinned Cython.
if ! python3.12 -m pip install --no-build-isolation -e . ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Unknown test failures are occurring due to the repository not being updated recently.
# The tests rely on nosetests, which is deprecated and incompatible with Python 3.12+ (due to the removed 'imp' module).
# These failures are observed on both x86 and other architectures.
# Updating the testing framework and dependencies is recommended to resolve these issues.
