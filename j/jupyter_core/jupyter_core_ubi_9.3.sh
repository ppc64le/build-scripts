#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package        : jupyter_core
# Version        : v5.3.0
# Source repo    : https://github.com/jupyter/jupyter_core.git
# Tested on      : UBI 9.3
# Language       : Python
# Travis-Check   : True
# Script License : Apache License, Version 2 or later
# Maintainer     : Vivek Sharma <vivek.sharma20@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such cases, please
#             contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=jupyter_core
PACKAGE_VERSION=${1:-v5.3.0}
PACKAGE_URL=https://github.com/jupyter/jupyter_core.git

# Install necessary system packages
yum install -y git gcc gcc-c++ gzip tar make wget xz cmake yum-utils openssl-devel openblas-devel bzip2-devel bzip2 zip unzip libffi-devel zlib-devel autoconf automake libtool cargo pkgconf-pkg-config.ppc64le info.ppc64le fontconfig.ppc64le fontconfig-devel.ppc64le sqlite-devel python-deve

# Clone the repository
git clone ${PACKAGE_URL} ${PACKAGE_NAME}
cd ${PACKAGE_NAME}
git checkout ${PACKAGE_VERSION}

# Install the package along with test dependencies
pip install pytest
pip install -e ".[test]"

# Run tests
if ! pytest -k "not (test_jupyter_path_prefer_env or test_jupyter_config_path_prefer_env or test_jupyter_path_user_site or test_jupyter_path_no_user_site)"; then
    echo "------------------$PACKAGE_NAME: Tests_Fail------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Tests_Fail"
    exit 1
else
    echo "------------------$PACKAGE_NAME: Install & test both success ---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
