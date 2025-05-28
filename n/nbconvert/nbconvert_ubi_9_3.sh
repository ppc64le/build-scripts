#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : nbconvert
# Version       : v7.16.4
# Source repo   : https://github.com/jupyter/nbconvert
# Tested on     : UBI: 9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Anumala Rajesh <Anumala.Rajesh@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex

PACKAGE_NAME=nbconvert
PACKAGE_VERSION=${1:-v7.16.4}
PACKAGE_URL=https://github.com/jupyter/nbconvert

yum install -y git python3.12 python3.12-devel python3.12-pip wget gcc-toolset-13
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH 

# Clone package repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
python3.12 -m pip install pytest

# Install
if ! python3.12 -m pip install .; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi 

# Test
python3.12 -m pip install ".[test]" 

# Skipping tests because dependencies (pandoc, texlive-xetex, inkscape, qt5-qtwebkit-devel, qt5-qtwebengine)
# are not compatible with ppc64le architecture.
if ! pytest -k "not test_asciidoc and not test_html and not test_rst and not test_slides and not test_templateexporter and not test_nbconvertapp and not test_markdown"; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
	exit 2
else
	echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_and_Test_Success"
	exit 0
fi