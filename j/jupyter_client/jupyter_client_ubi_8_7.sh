#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : jupyter_client
# Version       : v8.6.0
# Source repo   : https://github.com/jupyter/jupyter_client
# Tested on     : UBI: 8.7
# Language      : python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e


# Variables
export PACKAGE_VERSION=${1:-"v8.6.0"}
export PACKAGE_NAME=jupyter_client
export PACKAGE_URL=https://github.com/jupyter/jupyter_client

# Install dependencies
yum install -y gcc gcc-c++ make cmake git wget  autoconf automake libtool pkgconf-pkg-config.ppc64le info.ppc64le python39-devel.ppc64le curl gzip tar bzip2 zip unzip zlib-devel yum-utils fontconfig.ppc64le fontconfig-devel.ppc64le openssl-devel python39-setuptools

yum install -y  libffi-devel openssl-devel python39-cryptography.ppc64le python3-cryptography.ppc64le  gcc gcc-c++ make cmake

yum install -y python-virtualenv-doc.noarch python39-scipy.ppc64le python39-pip.noarch socat libicu libicu-devel libss libssh-devel libssh libpng libpng-devel libjpeg-turbo-devel libjpeg-turbo libX11-devel libX11 libXext gcc-gfortran

yum install -y sqlite-libs.ppc64le sqlite-devel.ppc64le sqlite.ppc64le fontconfig.ppc64le fontconfig-devel.ppc64le openblas.ppc64le freetype.ppc64le freetype-devel.ppc64le iproute.ppc64le net-tools.ppc64le net-snmp.ppc64le

pip3 install --upgrade pip
pip3 install cryptography
pip3 install hatch
PATH=$PATH:/usr/local/bin/


# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Build package
if !(hatch run docs:build) ; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Run test cases
if !(hatch -vv run test:nowarn); then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi

