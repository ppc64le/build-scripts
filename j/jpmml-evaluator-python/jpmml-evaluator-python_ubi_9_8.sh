#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : jpmml-evaluator-python
# Version       : 0.10.5
# Source repo   : https://github.com/jpmml/jpmml-evaluator-python
# Tested on     : UBI: 9.8
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Saloni Bhosale <Saloni.Bhosale@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -ex

PACKAGE_NAME=jpmml-evaluator-python
PACKAGE_VERSION=${1:-0.10.5}
PACKAGE_URL=https://github.com/jpmml/jpmml-evaluator-python

# Install dependencies
dnf install -y \
    git \
    gcc \
    gcc-c++ \
    gcc-gfortran \
    make \
    cmake \
    python3 \
    python3-pip \
    python3-devel \
    java-21-openjdk-devel \
    procps-ng

# Configure Java
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which javac))))
export PATH=$JAVA_HOME/bin:$PATH

# Install Apache Ant
mkdir -p /opt/ant
cd /opt/ant

curl -L https://dlcdn.apache.org/ant/binaries/apache-ant-1.10.18-bin.tar.gz | tar -xz

export ANT_HOME=/opt/ant/apache-ant-1.10.18
export PATH=$PATH:$ANT_HOME/bin

# Clone package repository
cd /root

git clone $PACKAGE_URL
cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

# Upgrade packaging tools
pip3 install --upgrade pip setuptools wheel

# Build wheel
if ! pip3 wheel .; then
    echo "------------------$PACKAGE_NAME:wheel_build_fails---------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_VERSION | GitHub | Fail | Wheel_Build_Fails"
    exit 1
fi

# Install package
if ! pip3 install .; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_VERSION | GitHub | Fail | Build_Fails"
    exit 1
fi

# Validation
if ! python3 -c "import jpmml_evaluator"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_VERSION | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_VERSION | GitHub | Pass | Install_and_Test_Success"
    exit 0
fi
